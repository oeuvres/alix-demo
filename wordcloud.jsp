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
alix.fr.Tag,
alix.fr.Occ,
alix.fr.Tokenizer,
alix.fr.Lexik
"%>
<%
  request.setCharacterEncoding("UTF-8");
%>
<%@include file="common.jsp" %>
<%
String bibcode = request.getParameter("bibcode");
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
a.mot { font-family: Georgia, serif; position: absolute; display: block; white-space: nowrap; color: rgba( 128, 0, 0, 0.9); }
a.SUB { color: rgba( 0, 0, 0, 0.6); font-family: "Arial", sans-serif; font-weight: 700; }
a.ADJ { color: rgba( 255, 0, 0, 0.7); }
a.VERB { color: rgba( 32, 128, 32, 0.8);  }
a.ADV { color: rgba( 0, 0, 255, 0.8); }
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
      </form>
      <div id="nuage"></div>
      <script>
   
<%
WordEntry entry;
HashSet<String> filter = new HashSet<String>(); 
for (String w: new String[]{
    "aller", "arriver", "attendre", "connaître", "croire", "demander", "devenir", "donner", "dire", 
    "entendre", "laisser", "paraître", "passer",
    "permettre", "prendre", "rendre", "répondre", "rester", "tenir", "venir", "voir", "vouloir", 
    "savoir", "servir", 
    "sortir", "trouver"
}) filter.add( w );

if ( bibcode != null ) {
  out.println("var list = [");
  TermDic dic = gdic( pageContext, bibcode );
  int max = 10000;
  String[] words = dic.byCount( 10000 );
  int lines = 300;
  int fontmin = 10;
  float fontmax = 140;
  int countmax = 0;
  int count;
  // loop on text forms in
  for (int i = 0; i < max; i++) {
    if (Lexik.isStop( words[i] )) continue;
    if ( filter.contains( words[i] )) continue;
    int tag = dic.tag( words[i] );
    if ( tag == Tag.VERBsup ) continue;
    if ( Tag.isName( tag )) tag = Tag.NAME;
    if ( Tag.isVerb( tag )) tag = Tag.VERB;
    if ( Tag.isAdv( tag )) tag = Tag.ADV;
    count = dic.count(words[i]);
    if ( countmax == 0 ) countmax = count;
    out.print("{ word:\"");
    out.print( words[i] ) ;
    out.print("\", weight:");
    // out.print(count + " " );
    // out.print( fontdf.format( fontmax*Math.log10(1+9.0*count/countmax) ) );
    out.print( fontdf.format( (1.0*count/countmax) *fontmax+fontmin ) );
    out.print(", attributes:{ class:\"mot ");
    out.print(Tag.label( tag ));
    out.println("\" } },");
    if (--lines <= 0 ) break;
  }
  out.println("];");
  out.println("WordCloud(document.getElementById('nuage'), { minRotation: -Math.PI/3, maxRotation: Math.PI/3,"
   + "rotateRatio: 0.6, shape: 'square', rotationSteps: 6, gridSize:0, list: list, fontFamily:'Verdana, sans-serif' } );");
}
%>
      </script>
    </article>
  </body>
</html>
