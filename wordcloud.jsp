<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.IOException,
java.io.BufferedReader,
java.io.InputStream,
java.nio.charset.StandardCharsets,
java.nio.file.Files,
java.nio.file.Path,
java.nio.file.Paths,
java.text.DecimalFormat,
java.util.Arrays,
java.util.HashSet,
java.util.LinkedHashMap,
java.util.Scanner,

alix.util.Char,
alix.util.TermDic,
alix.fr.Lexik,
alix.fr.Occ,
alix.fr.Tag,
alix.fr.Tokenizer,
alix.fr.WordEntry

"%>
<%@include file="common.jsp" %>
<%
String bibcode = request.getParameter("bibcode");
String log = request.getParameter("log");
if ( log != null && log.isEmpty() ) log = null;
String frantext = request.getParameter("frantext");
DecimalFormat fontdf = new DecimalFormat("#");

%>
<!DOCTYPE html>
<html>
  <head>
    <title>Nuage de mots</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <script src="lib/wordcloud2.js">//</script>
    <style>
#nuage { height: 600px; background: #FFF; }
#nuage a { text-decoration: none; }
a.mot { font-family: Georgia, serif; position: absolute; display: block; white-space: nowrap; color: rgba( 128, 0, 0, 0.9); }
a.SUB { color: rgba( 32, 32, 32, 0.6); font-family: "Arial", sans-serif; font-weight: 700; }
a.ADJ { color: rgba( 128, 128, 192, 0.8); }
a.VERB { color: rgba( 255, 0, 0, 1 );  }
a.ADV { color: rgba( 64, 128, 64, 0.8); }
a.NAME { padding: 0 0.5ex; background-color: rgba( 192, 192, 192, 0.2) ; color: #FFF; 
text-shadow: #000 0px 0px 5px;  -webkit-font-smoothing: antialiased;  }
    </style>
  </head>
  <body>
    <article id="article">
      <form method="GET">
        <a href=".">◀ Alix</a>
        <select name="bibcode" onchange="this.form.submit()">
          <% seltext( pageContext, bibcode );  %>
        </select>
        <% String checked = ""; if (frantext != null) checked =" checked=\"checked\""; %>
        <label>Filtre Frantext <input name="frantext" <%= checked %> type="checkbox"/></label>
        <button>▶</button>
      </form>
      <div id="nuage"></div>
      <script>
   
<%HashSet<String> filter = new HashSet<String>(); 
for (String w: new String[]{
    "aller", "arriver", "attendre", "connaître", "croire", "demander", "devenir", "devoir", "donner", "dire", 
    "entendre", "laisser", "paraître", "passer",
    "permettre", "pouvoir", "prendre", "rendre", "répondre", "rester", "tenir", "venir", "voir", "vouloir", 
    "savoir", "servir", 
    "sortir", "trouver"
}) filter.add( w );

HashSet<String> filter2 = new HashSet<String>(); 
for (String w: new String[]{
    "abbé", "baron", "docteur", "cher", "comte", "duc", "duchesse", "évêque", "lord", "madame", "mademoiselle", 
    "maître", "marquis", "marquise", "miss", "pauvre", "point", "prince", "princesse", "professeur", "sir"
}) filter2.add( w );

if ( bibcode != null ) {
  out.println("var list = [");
  TermDic dic = dic( pageContext, bibcode );
  long occs = dic.occs();
  String[] word = dic.byCount( 100000 );
  int lines = 300;
  int fontmin = 15;
  float fontmax = 60;
  int scoremax = 0;
  int score;
  WordEntry entry;
  float franfreq;
  double bias = 0;
  // loop on text forms in
  int max = word.length;
  for (int i = 0; i < max; i++) {
    int tag = dic.tag( word[i] );
    if ( Tag.pun( tag )) continue;
    if ( frantext != null ) {
      if ( tag != Tag.SUB && tag != Tag.ADV && tag != Tag.ADJ && tag != Tag.VERB ) continue;
      if ( filter2.contains( word[i] )) continue;
      float ratio = 4F;
      if ( tag == Tag.SUB) ratio = 12F;
      else if ( tag == Tag.VERB) ratio = 7F;
      
      if ("devoir".equals( word[i] )) entry = Lexik.entry( "doit" );
      else entry = Lexik.entry( word[i] );
      // locutions adverbiales sans stats
      if ( entry == null && tag == Tag.ADV) continue;
      if ( entry == null && tag == Tag.VERB) continue; // compound verbs, no stats
      if ( entry == null ) franfreq = 0;
      else if ( tag == Tag.SUB ) franfreq = entry.orthfreq ;
      else franfreq = entry.lemfreq ;
      // if ( franfreq == 0 ) continue;
      // if ( Tag.isDet( tag )) continue;
      // if ( tag == Tag.PROrel ) continue;
      // do not start with a non significant word
      if ( scoremax == 0 && tag != Tag.SUB && tag != Tag.VERB && tag != Tag.ADJ && tag != Tag.ADV ) continue;
      score = dic.count( word[i] );
      double myfreq = 1.0*score*1000000/occs;
      if ( myfreq/franfreq < ratio ) continue;
      // log = "??";
    }
    else {
      if (Lexik.isStop( word[i] )) continue;
      if ( Tag.name( tag )) tag = Tag.NAME;
      if ( Tag.verb( tag )) tag = Tag.VERB;
      if ( Tag.adv( tag )) tag = Tag.ADV;
      if ( tag == Tag.VERBsup ) continue;
      if ( filter.contains( word[i] )) continue;
      score = dic.count(word[i]);
    }
    if ( scoremax == 0 ) scoremax = score;

    out.print("{ word:\"");
    if ( word[i].indexOf( '"' ) > -1 ) word[i] = word[i].replace( "\"", "\\\"" ); 
    out.print( word[i] ) ;
    out.print("\", weight:");
    // out.print(count + " " );
    if ( log != null ) out.print( fontdf.format( fontmin + (fontmax - fontmin)*Math.log10(1+9.0*score/scoremax) ) );
    else out.print( fontdf.format( (1.0*score/scoremax) *fontmax+fontmin ) );
    out.print(", attributes:{ class:\"mot ");
    out.print(Tag.label( tag ));
    out.println("\", target:\"grep\", href:\"grep.jsp?mot="+word[i]+"&bibcode="+bibcode+"\" }, bias:"+bias+" },");
    if (--lines <= 0 ) break;
  }
  out.println("];");
  out.println("WordCloud(document.getElementById('nuage'), { minRotation: -Math.PI/5, maxRotation: Math.PI/5,"
   + "rotateRatio: 0.5, shape: 'square', rotationSteps: 4, gridSize:5, list: list, fontFamily:'Verdana, sans-serif' } );");
}%>
      </script>
      <iframe name="grep" width="100%" allowfullscreen="true" style="min-height: 500px; border: none "></iframe>
    </article>
  </body>
</html>
