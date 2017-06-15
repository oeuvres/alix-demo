<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ page import="

java.io.File,
java.io.InputStream,
java.io.InputStreamReader,
java.io.IOException,
java.io.PrintWriter,
java.io.Reader,
java.text.DecimalFormat,
java.text.NumberFormat,
java.text.DecimalFormatSymbols,
java.util.Arrays,
java.util.Collections,
java.util.Enumeration,
java.util.HashMap,
java.util.HashSet,
java.util.Locale,
java.util.List,
java.util.Map,
java.util.Properties,

alix.sqlite.Dicovek,
alix.sqlite.Dicovek.SimRow,
alix.util.IntBuffer,
alix.util.IntTuple,
alix.util.IntVek,
alix.util.IntVek.Pair,
alix.util.IntVek.SpecRow,
alix.util.TermDic,
alix.fr.Lexik
"%><%!
/** Current vector space */
private Dicovek veks;
/** Writer */
private JspWriter printer;
final static int ROOT = 0;
final static int SIM = -1;
final static int COOC = -2;
final static HashSet<String> filter = new HashSet<String>();
static {
  for (String w: new String[]{
      "dire"
  }) filter.add( w );
}

private void graphdiv( final String id ) throws IOException
{
  printer.println("<div id=\""+id+"\" class=\"graph\" oncontextmenu=\"return false\" style=\"position:relative; \">");
  printer.println("  <div style=\"position: absolute; bottom: 0; right: 2px; z-index: 2; \">");
  printer.println("    <button class=\"colors but\" title=\"Gris ou couleurs\">◐</button>");
  printer.println("    <button class=\"shot but\" type=\"button\" title=\"Prendre une photo\">📷</button>");
  printer.println("    <button class=\"turnleft but\" type=\"button\" title=\"Rotation vers la gauche\">⤴</button>");
  printer.println("    <button class=\"turnright but\" type=\"button\" title=\"Rotation vers la droite\">⤵</button>");
  printer.println("    <button class=\"zoomin but\" style=\"cursor: zoom-in; \" type=\"button\" title=\"Grossir\">+</button>");
  printer.println("    <button class=\"zoomout but\" style=\"cursor: zoom-out; \" type=\"button\" title=\"Diminuer\">–</button>");
  printer.println("    <button class=\"but restore\" type=\"button\" title=\"Recharger\">O</button>");
  printer.println("    <button class=\"mix but\" type=\"button\" title=\"Mélanger le graphe\">♻</button>");
  printer.println("    <button class=\"FR but\" type=\"button\" title=\"Spacialisation Fruchterman Reingold\">☆</button>");
  printer.println("    <button class=\"atlas2 but\" type=\"button\" title=\"Démarrer ou arrêter la gravité atlas 2\">►</button>");
  printer.println("    <span class=\"resize interface\" style=\"cursor: se-resize; font-size: 1.3em; \" title=\"Redimensionner la feuille\">⬊</span>");
  printer.println("  </div>");
  printer.println("</div>");

}

private void sigmanodes( HashMap<Integer, int[]> nodes ) throws IOException
{
  printer.println( "  nodes: [" );
  // loop on nodes
  TermDic dic = veks.dic();
  int cooci = 0;
  int simi = 0;
  for ( Map.Entry<Integer, int[]> node : nodes.entrySet()) {
    int code = node.getKey();
    int type = node.getValue()[0];
    int size = node.getValue()[1];
    if ( size < 1 ) continue; // cut orphans ?
    int x = 0;
    int y = 0;
    double angle =0;
    String color="";
    String label = dic.label( code ).replace( '\'', '’' );
    
    if ( type == COOC ) { // cooccurrent
      size = size; 
      angle = Math.PI/4+Math.PI*cooci/3.27;
      long r = 500;
      cooci++;
      x = (int)( 2*r*(Math.cos(angle) )) ;
      y = (int)( r*(Math.sin(angle) ));
      color = "rgba(128, 128, 128, 0.5)";
    }
    else if ( type == ROOT ) {
      size = dic.count( code ); 
      color = "rgba( 255, 0, 0, 0.3)";
      x = 0;
      y = 0;
    }
    else if ( type == SIM ) {
      size = dic.count( code ); 
      long r = 1000;
      simi++;
      angle = Math.PI/2+Math.PI*simi/2.69;
      x = (int)( 2*r* Math.cos(angle) );
      y = (int)( r* Math.sin(angle) );
      color = "rgba(0, 0, 192, 0.5)";
    }
    //    {id:'ribercour', label:"RIBERCOUR", size:13722, x:1.0, y: 5.5, color: "#4C4CFF", title: "Gentihomme Manceau & d\u00e9put\u00e9 de ce Pa\u00efs.", type:"drama"},
    printer.println("    {id:'n"+code+"', label:'"+label+"', size:"+size
    +", color:'"+color+"', x:"+x+", y:"+y+" },");
  }
  printer.println( "  ]" );
}

private void form( final String corpusdir, final String corpus, final String term ) throws IOException
{
  printer.println("<form id=\"form\">Alix, vecteurs de mots");
  printer.println("  <label>");
  printer.println("    <select name=\"corpus\" onchange=\"this.form.submit()\">");
  printer.println("      <option/>");
  //lister les fichiers de corpus
  File[] dir = new File( corpusdir ).listFiles();
  Arrays.sort( dir );
  for (final File file : dir ) {
    String key = file.getName();
    if ( key.startsWith( "." ) ) continue;
    // if ( file.isDirectory() ) key += "/";
    printer.print("<option");
    printer.print( " value=\""+key+"\"" );
    if ( key.equals( corpus ) ) printer.print( " selected=\"selected\"" );
    printer.print(">");
    int pos = key.lastIndexOf( "." );
    if ( pos > 3) printer.print( key.substring( 0, pos ) );
    else printer.print( key );
    printer.print("</option>\n");
  }
  printer.println("    </select>");
  printer.println("  </label>");
  printer.println("  <label>Mot <input size=\"10\" name=\"term\" value=\""+term+"\"/></label>");
  printer.println("  <button type=\"submit\" name=\"search\">Chercher</button>");
  printer.println("  <button type=\"submit\" name=\"clean\">Effacer</button>");
  printer.println("</form>");
}

%><%
request.setCharacterEncoding("UTF-8");
this.printer = out;
String term = request.getParameter( "term" );
if ( term == null || request.getParameter( "clean" ) != null ) term = "";
String corpus = request.getParameter( "corpus" );
String corpusdir = application.getRealPath("/WEB-INF/veks")+"/";

%><!DOCTYPE html>
<html>
  <head>
    <title>Alix, vecteurs de mots</title>
    <style>
* { box-sizing: border-box; }
html { height: 100%; }
body { font-family: sans-serif; height: 100%; margin: 0; padding:0;  }
table.page { border-collapse: separate;  border-spacing: 1em 0; width: 100%; }
#form { padding: 5px 1em; }
table.page td.col { vertical-align: top; }
td.term { white-space: nowrap; }
    </style>
    <script src="lib/sigma/sigma.min.js">//</script>
    <script src="lib/sigma/sigma.plugins.dragNodes.min.js">//</script>
    <script src="lib/sigma/sigma.exporters.image.js">//</script>
    <script src="lib/sigma/sigma.plugins.animate.js">//</script>
    <script src="lib/sigma/sigma.layout.fruchtermanReingold.js">//</script>
    <script src="lib/sigma/worker.js">//</script>
    <script src="lib/sigma/supervisor.js">//</script>
    <script src="lib/sigmot.js">//</script>
  </head>