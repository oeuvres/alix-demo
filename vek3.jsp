<%@ 
page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
import="

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
alix.sqlite.Dicovek.CosineRow,
alix.util.IntBuffer,
alix.util.IntTuple,
alix.util.IntVek,
alix.util.IntVek.Pair,
alix.util.IntVek.SpecRow,
alix.util.TermDic,
alix.util.TermDic.DicEntry,
alix.fr.Lexik
"%><%!/** Vector space */
private Dicovek veks;
/** Writer */
private JspWriter printer;
/**  */
final static int ROOT = 0;
final static int SIM = -1;
final static int COOC = -2;
final static HashSet<String> filter = new HashSet<String>();
static {
  for (String w: new String[]{
      "dire"
  }) filter.add( w );
}

private void sigma3( String term, int loops ) throws IOException
{
  int edgemax = 500;
  
  TermDic dic = veks.dic();
  boolean stop = true;
  if ( Lexik.isStop( term ) ) stop = false;
  HashMap<Integer, int[]> nodes = new HashMap<Integer, int[]>();
  List<CosineRow> sims = veks.sims( term, loops );
  if ( sims == null ) return;
  // do not repeat root -> cooc
  HashSet<IntTuple> done = new HashSet<IntTuple>();
  IntBuffer test = new IntBuffer(); // pair test

  int rootcode = 0;
  IntVek root = null;
  
  printer.println( "{" );
  printer.println( "  edges: [" );
  int edge = 0;
  List<SpecRow> edges = null;
  
  int sourcemax = 20;
  if ( sims.size() < sourcemax ) sourcemax = sims.size();
  int sourcei = 0;
  for ( CosineRow source:sims ) {
    printer.println("// —— "+dic.label( source.code ) );
    if ( stop && source.code < veks.stopoffset ) continue;
    if ( sourcei == 0 ) {
      nodes.put( source.code, new int[]{ ROOT, 0 } );
      rootcode = source.code;
      root = veks.vector( rootcode );
      sourcei++;
      continue;
    }
    nodes.put( source.code, new int[]{ SIM, 0 } );
    List<SpecRow> specs = root.specs( veks.vector(source.code) );
    int size = specs.size();
    if ( size > 500 ) specs.subList( 0, 500 ); 
    if ( edges == null ) edges = specs ;
    else edges.addAll( specs );
    if ( ++sourcei >= sourcemax) break;
  }
  Collections.sort( edges );
  for ( SpecRow row:edges) {
    if ( row.key < veks.stopoffset ) continue;
    String cooc = dic.label( row.key );
    if ( filter.contains( cooc )) continue;
    int[] node = nodes.get( row.key );
    if ( node == null ) {
      node = new int[]{ COOC, 0};
      nodes.put( row.key, node );
    }
    // SIM -> cooc
    nodes.get( row.target )[1]+=row.tval;
    nodes.get( row.key )[1]+=row.tval;
    printer.println( "    { id:'e"+edge+"', source:'n"+row.target+"', target:'n"+row.key+"', size:"+row.spec+" }, "
    +"// "+dic.label( row.target )+" "+cooc );
    edge++;
    // ROOT -> cooc
    test.set( 0, row.source ).set( 1, row.key );
    if ( done.contains( test ) ) continue;
    done.add( new IntTuple(test) );
    nodes.get( row.source )[1]+=row.sval;
    nodes.get( row.key )[1]+=row.sval;
    printer.println( "    { id:'e"+edge+"', source:'n"+row.source+"', target:'n"+row.key+"', size:"+row.spec+" }, "
    +"// "+dic.label( row.source )+" "+cooc );
    if ( ++edge >= edgemax ) break;
  }
  
  printer.println( "  ]," );
  sigmanodes( nodes );
  printer.print( "}" );
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
    // if ( size < 1 ) continue; // cut orphans ?
    int x = 0;
    int y = 0;
    double angle =0;
    String color="";
    String label = dic.label( code ).replace( '\'', '’' );
    
    if ( type == COOC ) { // cooccurrent
      size = size; 
      angle = Math.PI/4+Math.PI*cooci/3.27;
      long r = 1000;
      cooci++;
      x = (int)( 2*r*(Math.cos(angle) )) ;
      y = (int)( r*(Math.sin(angle) ));
      color = "rgba(128, 128, 128, 0.5)";
    }
    else if ( type == ROOT ) {
      size = dic.count( code ); 
      color = "rgba( 255, 0, 0, 0.3)";
      x = 0;
      y = 2000;
    }
    else if ( type == SIM ) {
      size = dic.count( code ); 
      long r = 500;
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

}%><%
this.printer = out;
request.setCharacterEncoding("UTF-8");
String term = request.getParameter( "term" );
if ( term == null ) term = "";
String corpus = request.getParameter( "corpus" );
String corpusdir = application.getRealPath("/WEB-INF/veks")+"/";
  /*
  String term = request.getParameter("term");
  if ( term == null ) term="";
  int vocab = 3000;
  try {
    vocab = Integer.parseInt( request.getParameter("vocab") );  
  } catch ( Exception e ) {};
  int hits = 30;
  try {
    hits = Integer.parseInt( request.getParameter("hits") );  
    if (hits < 0 || hits > 200) hits=30;
  } catch ( Exception e ) {};
  */
%><!DOCTYPE html>
<html>
  <head>
    <title>Dicovek</title>
    <style>
html { height: 100%; }
body { font-family: sans-serif; height: 100%; } 
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
  <body>
    <form style="position:absolute; z-index:3">
    <label>Corpus 
    <select name="corpus" onchange="this.form.submit()">
      <option/>
<%
//lister les fichiers de corpus
File[] dir = new File( corpusdir ).listFiles();
Arrays.sort( dir );
for (final File file : dir ) {
  String key = file.getName();
  if ( key.startsWith( "." ) ) continue;
  // if ( file.isDirectory() ) key += "/";
  out.print("<option");
  if ( key.equals( corpus ) ) out.print( " selected=\"selected\"" );
  out.print(">");
  out.print( key );
  out.print("</option>\n");  
}


%>
    </select>
    </label>
    <label>Mot <input name="term" value="<%= term %>"/></label>
    <button type="submit">Chercher</button>
    </form>
<%
if ( corpus != null && !corpus.isEmpty() ) {
  // charger le corpus en mémoire s’il n’y est pas
  veks = (Dicovek)application.getAttribute( corpus );
  // test freshness
  if ( veks != null ) {
    if ( new File( corpusdir, corpus ).lastModified() > veks.modified() ) veks = null;
  }
  if ( veks == null) {
    String glob = corpusdir + corpus;
    if ( new File( glob ).isDirectory() ) glob = new File( glob ).getCanonicalPath()+"/*";
    int wing = 5;
    veks = new Dicovek( -wing, wing );
    out.print("<pre>");
    veks.walk( glob, new PrintWriter(out) );
    out.print("</pre>");
    application.setAttribute( corpus, veks );
  }

}
if ( veks != null ) {
//     <button class="FR but" type="button" title="Spacialisation Fruchterman Reingold">☆</button>
%>
<div id="graph" class="graph" oncontextmenu="return false" style="position:relative; height: 90%; ">
  <div style="position: absolute; bottom: 0; right: 2px; z-index: 2; ">
    <button class="colors but" title="Gris ou couleurs">◐</button>
    <button class="shot but" type="button" title="Prendre une photo">📷</button>
    <button class="turnleft but" type="button" title="Rotation vers la gauche">⤴</button>
    <button class="turnright but" type="button" title="Rotation vers la droite">⤵</button>
    <button class="zoomin but" style="cursor: zoom-in; " type="button" title="Grossir">+</button>
    <button class="zoomout but" style="cursor: zoom-out; " type="button" title="Diminuer">–</button>
    <button class="but restore" type="button" title="Recharger">O</button>
    <button class="mix but" type="button" title="Mélanger le graphe">♻</button>
    <button class="atlas2 but" type="button" title="Démarrer ou arrêter la gravité">►</button>
    <span class="resize interface" style="cursor: se-resize; font-size: 1.3em; " title="Redimensionner la feuille">⬊</span>
  </div>
</div>
<script>
(function () {
  var data = <% sigma3( term, -1 ); %>;
  var graph = new sigmot("graph", data ); //
})(); 

  </script>
  <% } %>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>