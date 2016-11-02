<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.IOException,
java.io.BufferedReader,
java.nio.charset.StandardCharsets,
java.nio.file.Files,
java.nio.file.Path,
java.nio.file.Paths,
java.text.DecimalFormat,
java.text.DecimalFormatSymbols,
java.util.Arrays,
java.util.HashSet,
java.util.Locale,
java.util.List,

site.oeuvres.util.Char,
site.oeuvres.util.CompDic,
site.oeuvres.util.CompDic.Balance,
site.oeuvres.util.TermDic,
site.oeuvres.fr.Cat,
site.oeuvres.fr.Occ,
site.oeuvres.fr.Tokenizer,
site.oeuvres.fr.Lexik,
site.oeuvres.fr.LexikEntry
"%>
<%!
/** liste de textes */
static String[][] catalog = {
  new String[] {"corneillep", "corneillep.txt", "Corneille, Pierre", "Théâtre"},
  new String[] {"corneillet", "corneillet.txt", "Corneille, Thomas", "Théâtre"},
  new String[] {"dumas", "dumas.txt", "Dumas", "Romans"},
  new String[] {"moliere", "moliere.txt", "Molière", "Théâtre"},
  new String[] {"proust_recherche", "proust_recherche.xml", "Proust", "À la recherche du temps perdu"},
  new String[] {"racine", "racine.txt", "Racine", "Théâtre"},
  new String[] {"sade", "sade.txt", "Sade", "Récits"},
  new String[] {"stendhal", "stendhal.xml", "Stendhal", "Romans"},
  new String[] {"zola", "zola.xml", "Zola", "Romans"},
};
public static final String[] _FILTER = new String[] { "aller", "bientôt", "devoir", "demander",
    "donner", "faire", "falloir", "paraître", "pouvoir", "prendre", "savoir", "venir", "voir", "vouloir" };
public static final HashSet<String> FILTER = new HashSet<String>(Arrays.asList(_FILTER));
/**
 * Récupérer un dictionnaire par identifiant
 */
public TermDic get( ServletContext application, final String code ) throws IOException 
{
  String att = "M"+code;
  TermDic dico = (TermDic)application.getAttribute( att );
  if ( dico != null ) return dico;
  // retrouver l’enregistrement
  int i = 0;
  String[] bibl = null;
  while ( i < catalog.length) {
    if (catalog[i][0].equals( code )) {
      bibl = catalog[i];
      break;
    }
    i++;
  }
  // texte inconnu
  if ( bibl == null ) return null;
  String home = application.getRealPath("/");
  String filepath = home + "/textes/" + bibl[1];
  Path path =  Paths.get( filepath );
  dico = parse( new String( Files.readAllBytes( path ), StandardCharsets.UTF_8 ) );
  application.setAttribute( att, dico );
  return dico;
}
/**
 * Charger un dictionnaire avec les mots d’un texte
 */
public TermDic parse( String text ) throws IOException {
  TermDic dic = new TermDic();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  short cat;
  while ( toks.word( occ ) ) {
    cat = occ.cat();
    if ( Cat.isVerb( cat ) ) {
      dic.add( occ.lem() );
    }
    else dic.add( occ.orth() );
  }
  return dic;
}
/**
 *
 */
public int log ( double percent )
{
  int sign = 1;
  if ( percent < 50 ) sign = -1;
  percent = 1+9*Math.abs(percent - 50)/50;
  percent = 50+sign*50* Math.log10( percent );
  return (int)percent;
}


%>
<%
request.setCharacterEncoding("UTF-8");
long time;
DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.ENGLISH);
DecimalFormat dec1 = new DecimalFormat("#.0", symbols);

%>
<!DOCTYPE html>
<html>
  <head>
    <title>Comparateur de fréquences lexicales</title>
    <link rel="stylesheet" type="text/css" href="http://svn.code.sf.net/p/obvil/code/theme/obvil.css" />
    <style type="text/css">
html, body { height: 100%; background-color: #f3f2ec; }
article { height: 100%; margin-top:0; padding: 0 2em 0 2em; font-family: sans-serif;   }
select, button {font-size: 18px; font-family: sans-serif; }
textarea { border: none; }
div:after, div:before, form:after, form:before { content:" "; visibility: hidden; display: block; clear: both; height: 0; }

.rule { border-bottom: 1px solid #000000; height: 1em; position: fixed; width: 100%; }
.rule .l, .rule .c, .rule .r { background: transparent; position: absolute; padding: 0 0.5ex; }
.rule .r { text-align: right; border-right: 1px solid #000; }
.rule .l { text-align: left;  border-left: 1px solid #000; }
.rule .c { text-align: center; transform: translate(-50%, 0); }

.bar { text-align:left; position: absolute; width: 100%; border-bottom: 1px solid rgba( 0, 0, 0, 0.2); z-index: 1; }

.board { color: rgba(0, 0, 0, 0.7); height: 80%; bottom: 0; font-size: 18px; position: relative; }
.board .l, .board .c, .board .r  { position: absolute; background-color: rgba(255, 255, 255, 0.5); padding: 0 1ex;  z-index: 2; }
.board .r { text-align: right; border-right: 1px solid #F00; }
.board .l { text-align: left;  border-left: 1px solid #F00; }
.board .c { text-align: center; transform: translate(-50%, 0); }


    </style>
  </head>
  <body>
  <%
  int gap = 45;
  int lbound = 50 - gap;
  int rbound = 50 + gap;
  long laps;
  TermDic dic1 = null;
  TermDic dic2 = null;
  boolean go = false;
  %>
    <article>
    <h1><a href=".">Alix</a> : fréquences lexicales comparées</h1>
    <%
    String text1 = request.getParameter( "text1" );
    String text2 = request.getParameter( "text2" );
    if ( text1==null ) text1="";
    if ( text2==null ) text2="";
    if ( !text1.isEmpty() && !text2.isEmpty() ) {
      dic1 = parse( text1 );
      dic2 = parse( text2 );
      go = true;
    }
    %>
    <form action="#board" style="width: 100%; text-align: center; z-index: 2; clear: both; border: #FFFFFF solid 1px; padding: 0; margin: 0 0 1ex 0; " method="post">
      <textarea name="text1" style="width: 45%; height: 10em; float: left; "><%=text1%></textarea>
      <textarea name="text2" style="width: 45%; height: 10em; float: right"><%=text2%></textarea>
      <button type="submit" name="text">Comparer</button>
    </form>
    <%
    
    %>
    <%
    final String selected = " selected=\"selected\"";
    String sel;
    %>
    <form action="?#board" style="width: 100%; text-align: center; z-index: 2; position: relative; clear: both; " method="get">
      <select name="ref1" style="float: left">
      <%
        String ref1 = request.getParameter("ref1");
        if ( !text1.isEmpty() ) ref1 = null;
        sel = "";
        if ( ref1 == null ) sel = selected;
        out.print("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+sel+">Choisir un texte…</option>");
        for ( int i = 0; i < catalog.length; i++) {
          sel = "";
          if ( catalog[i][0].equals( ref1 ) ) sel = selected;
          out.print("<option value=\""+catalog[i][0]+"\""+sel+">"+catalog[i][2]+". "+catalog[i][3]+"</option>");
        }
      %>
      </select>
      <button type="submit">Comparer</button>
      <select name="ref2" style="float: right; text-align: right; ">
      <%
        String ref2 = request.getParameter("ref2");
        if ( !text2.isEmpty() ) ref2 = null;
        sel = "";
        if ( ref2 == null ) sel = selected;
        out.print("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+sel+">Choisir un texte…</option>");
        for ( int i = 0; i < catalog.length; i++) {
          sel = "";
          if ( catalog[i][0].equals( ref2 ) ) sel = selected;
          out.print("<option value=\""+catalog[i][0]+"\""+sel+">"+catalog[i][2]+". "+catalog[i][3]+"</option>");
        }
      %>
      </select>
    </form>
<%
if ( ref1 != null && ref2 != null) {
  
  time = System.nanoTime();
  dic1 = get( application, ref1 );
  laps = ((System.nanoTime() - time) / 1000000);
  if ( laps > 1 ) out.println( "<p>"+ref1+": dictionnaire construit en "+ laps + " ms</p>");
  
  time = System.nanoTime();
  dic2 = get( application, ref2 );
  laps = ((System.nanoTime() - time) / 1000000);
  if ( laps > 1 ) out.println( "<p>"+ref2+": dictionnaire construit en "+ laps + " ms</p>");
  
  go = true;
}
%>
      <div class="rule">
        <div class="l" style="left:<%=log(0)%>%">100</div>
        <div class="l" style="left:<%=log(10)%>%">80</div>
        <div class="l" style="left:<%=log(20)%>%">60</div>
        <div class="l" style="left:<%=log(30)%>%">40</div>
        <div class="l" style="left:<%=log(40)%>%">20</div>
        <div class="c" style="left:<%=log(50)%>%">0</div>
        <div class="r" style="right:<%=log(40)%>%">20</div>
        <div class="r" style="right:<%=log(30)%>%">40</div>
        <div class="r" style="right:<%=log(20)%>%">60</div>
        <div class="r" style="right:<%=log(10)%>%">80</div>
        <div class="r" style="right:<%=log(0)%>%">100</div>
      </div>
    <div class="center" style=" left:<%=log(lbound) %>%; right:<%=log(100-rbound) %>%; position: absolute; background: #FFFFFF;
        border-left: 4px rgba(255,0,0,0.3) solid; border-right: 4px rgba(255,0,0,0.3) solid; height "> </div>  
      <div class="board" id="board" >
<%
// la vue de comparaison
while ( go ) {
  if ( dic1 == null ) out.println( "<p>"+ref1+": texte inconnu de cette base.</p>" );
  if ( dic2 == null ) out.println( "<p>"+ref2+": texte inconnu de cette base.</p>" );
  if ( dic1 == null || dic2 == null ) break;
  CompDic comp = new CompDic();
  comp.add1( dic1 );
  comp.add2( dic2 );
  List<Balance> list = comp.sort();
  Balance mot;
  int size = list.size();
  int max = 400;
  int n = 1;
  float top = 0;
  int left;
  int last = 50;
  String cat = "c";
  String style = "";
  StringBuilder sb = new StringBuilder();
  for(int i = 0; i < size ; i++) {
    mot = list.get( i );
    left = (int)(100.0 * mot.freq2/ (mot.freq1 + mot.freq2) ) ;
    if ( left < 48 ) {
      cat = "l";
      style= " left:"+log(left)+"%; ";
    }
    else if ( left > 52 ) {
      cat = "r";
      style= " right:"+log(100-left)+"%; ";
    }
    else {
      cat = "c";
      style= " left:"+log(left)+"%; ";
      // continue;
    }
    // filters on the center
    if ( left > lbound || left < rbound ) {
      if ( Lexik.isStop( mot.term ) ) continue;
      if ( FILTER.contains(mot.term) ) continue;
    }
    // si le mot suivant n’est pas du même côté espacement plus petit
    if ( Math.abs(last - left) < 20 ) top = (float)Math.round( top*10+8 )/10;
    else top = (float)Math.round( top*10+3 )/10;
    out.println( "<div title=\""+(int)mot.freq1+" ("+left+"%) "+(int)mot.freq2
        +"\" class=\""+cat+"\" style=\"top:"+top+"em; "+style+"\">"+mot.term+"</div>" );
    if ( (n % 25) == 0 ) {
      out.println("<div class=\"bar\" style=\"top:"+top+"em\">"+n+"</div>");
    }
    n++;
    if ( n > max ) break;
    last = left;
  }

  
  break;
}
      %>
      </div>
    </article>
  </body>
</html>
