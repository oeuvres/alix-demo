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
alix.util.IntVek.Pair,alix.util.SpecRow,alix.util.TermDic,alix.util.TermDic.DicEntry,alix.fr.Lexik"%><%!/** Vector space */
private Dicovek veks;
/** Writer */
private JspWriter printer;
/**  */
final static int ROOT = 0;
final static int SIM = -1;
final static int COOC = -2;

private void sigma3( String term, int loops ) throws IOException
{
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
  int sourcemax = 20;
  if ( sims.size() < sourcemax ) sourcemax = sims.size();
  IntVek root = null;
  int sourcei = 0;
  int targetmax = 10;
  
  printer.println( "{" );
  printer.println( "  edges: [" );
  int edge = 0;
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
    List<SpecRow> targets = root.specs( veks.vector(source.code) );
    int targeti = 0;
    for ( SpecRow target:targets) {
      if ( target.key < veks.stopoffset ) continue;
      int[] node = nodes.get( target.key );
      if ( node == null ) {
        node = new int[]{ COOC, 0};
        nodes.put( target.key, node );
      }
      if ( node[0] == COOC ) node[1] += target.val2;
      // SIM -> cooc
      printer.println( "    { id:'e"+edge+"', target:'n"+source.code+"', source:'n"+target.key+"', size:"+target.val2+" }, "
      +"// "+dic.label( source.code )+" "+dic.label( target.key ) );
      edge++;
      // ROOT -> cooc
      test.set( 0, rootcode ).set( 1, target.key );
      if ( done.contains( test ) ) continue;
      done.add( new IntTuple(test) );
      if ( node[0] == COOC ) node[1] += target.val1;
      printer.println( "    { id:'e"+edge+"', target:'n"+rootcode+"', source:'n"+target.key+"', size:"+target.val1+" }, "
      +"// "+dic.label( rootcode )+" "+dic.label( target.key ) );
      edge++;
      if ( ++targeti >= targetmax ) break;
    }
    if ( ++sourcei >= sourcemax) break;
  }
  printer.println( "  ]," );
  sigmanodes( nodes );
  printer.print( "}" );
}

private void sigma2( String term, int loops ) throws IOException
{
  TermDic dic = veks.dic();
  boolean stop = true;
  if ( Lexik.isStop( term ) ) stop = false;
  HashMap<Integer, int[]> nodes = new HashMap<Integer, int[]>();
  List<CosineRow> sims = veks.sims( term, loops );
  if ( sims == null ) return;
  int sourcemax = 20;
  if ( sims.size() < sourcemax ) sourcemax = sims.size();
  // collect sims
  int[] sources = new int[sourcemax];
  int i = 0 ;
  for ( CosineRow source:sims ) {
    if ( stop && source.code < veks.stopoffset ) continue;
    sources[i] = source.code;
    // source.count ? Ou juste du relatif ?
    if ( i == 0 ) nodes.put( source.code, new int[]{ ROOT, 0 } );
    else nodes.put( source.code, new int[]{ SIM, 0 } );
    if ( ++i >= sourcemax) break;
  }
  // loop on coocs from root term
  IntVek vector = veks.vector( sources[0] );
  if ( vector == null ) return; // WHAT ???
  printer.println( "{" );
  printer.println( "  edges: [" );
  int edge = 0;
  int edgemax = 500;
  for ( Pair target: vector.toArray() ) {
    // no output for stopwords
    if ( stop && target.key < veks.stopoffset ) continue;
    printer.println("// —— "+dic.label(target.key)+":"+target.value );
    // root to cooc
    // get the vector of this cooc 
    vector = veks.vector( target.key );
    if ( vector == null ) {
      printer.println("// ? No vector for?: "+dic.label(target.key) );
      continue;
    }
    if ( target.value != vector.get(sources[0]) ) {
      printer.println("// WHAT ? "+target.value+" != "+ vector.get(sources[0]));
    }
    if ( target.value < 1 ) continue;
    // loop on all sources and
    for ( i=0; i < sourcemax; i++ ) {
      int size = vector.get( sources[i] );
      if ( size < 3 ) continue;
      int[] row = nodes.get( target.key );
      if ( row == null ) nodes.put( target.key, new int[]{ COOC, target.value } );
      else if ( row[0] == COOC ) row[1] += size;
      // increment the source
      nodes.get( sources[i] )[1]+=size;
      printer.println( "    { id:'e"+edge+"', source:'n"+sources[i]+"', target:'n"+target.key+"', size:"+size+" }, "
      +"// "+dic.label( sources[i] )+" "+dic.label( target.key ) );
      if ( ++edge >= edgemax ) break;
    }
    if ( ++edge > edgemax ) break;
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
    if ( size == 0 ) size = dic.count( code ); // if no value provide, take absolute count
    // if ( size < 1 ) continue; // cut orphans ?
    int x = 0;
    int y = 0;
    double angle =0;
    String color="";
    
    if ( type == COOC ) { // cooccurrent
      angle = Math.PI/4+Math.PI*cooci/3.27;
      long r = 500;
      cooci++;
      x = (int)( 2*r*(Math.cos(angle) )) ;
      y = (int)( r*(Math.sin(angle) ));
      color = "rgba(0, 0, 0, 0.1)";
    }
    else if ( type == ROOT ) {
      color = "rgba( 255, 0, 0, 0.3)";
      x = 0;
      y = 0;
    }
    else if ( type == SIM ) {
      long r = 1000;
      simi++;
      angle = Math.PI*simi/2.69;
      x = (int)( 2*r* Math.cos(angle) );
      y = (int)( r* Math.sin(angle) );
      color = "rgba(0, 0, 192, 0.5)";
    }
    //    {id:'ribercour', label:"RIBERCOUR", size:13722, x:1.0, y: 5.5, color: "#4C4CFF", title: "Gentihomme Manceau & d\u00e9put\u00e9 de ce Pa\u00efs.", type:"drama"},
    printer.println("    {id:'n"+code+"', label:'"+dic.label( code ).replace( '\'', '’' )+"', size:"+size
    +", color:'"+color+"', x:"+x+", y:"+y+" },");
  }
  printer.println( "  ]" );

}

/**
 * Parcourir les cooccurrents
 */
private void sigma( String term, int loops ) throws IOException
{
  boolean stop = true;
  if ( Lexik.isStop( term ) ) stop = false;
  if ( null == term || "".equals( term )) return;
  List<CosineRow> sims = veks.sims( term, loops );
  if ( sims == null ) return;
  // collect infos on all nodes
  HashMap<Integer, int[]> nodes = new HashMap<Integer, int[]>();
  HashSet<IntTuple> done = new HashSet<IntTuple>();
  // output edges
  printer.println( "{" );
  printer.println( "  edges: [" );
  int edge = 1;
  // int edgemax = 500;
  int sourcemax = 20;
  int sourcei = 0;
  int targetmax = 20;
  IntBuffer test = new IntBuffer();
  // peupler un hash de sims
  
  for ( CosineRow source:sims ) {
    if ( source.code < veks.stopoffset ) continue; // filter 
    IntVek vector = veks.vector( source.code );
    if ( vector == null ) continue; // possible ?
    if ( sourcei == 0 ) nodes.put( source.code, new int[]{ ROOT, source.count } );
    else nodes.put( source.code, new int[]{ SIM, source.count } );
    Pair[] coocs = vector.toArray();
    int targeti = 0;
    for ( Pair target:coocs ) {
      // no output for stopwords
      if ( target.key < veks.stopoffset ) continue;
      
      test.set(0, source.code).set(1, target.key );
      if ( done.contains( test ) ) continue;
      //     {id:"e0", source:"roguespine", target:"roguespine", size:"716", color: "rgba(96, 96, 192, 0.3)", type:"drama"},
      printer.println( "    { id:'e"+edge+"', source:'n"+source.code+"', target:'n"+target.key+"', size:"+target.value+" }," );
      edge++;
      done.add( new IntTuple(test) );
      // new value
      if ( !nodes.containsKey( target.key ) ) nodes.put( target.key, new int[]{ COOC, target.value} );
      else {
        int[] row = nodes.get( target.key );
        // is not root or siminyme
        if ( row[0] == COOC ) {
          row[1] += target.value;
          nodes.put( target.key, row );
        }
      }
      if ( ++targeti >= targetmax ) break;
    }
    if ( ++sourcei >= sourcemax ) break;
  }
  printer.println( "  ]," );
  sigmanodes( nodes );
  printer.print( "}" );
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
for (final File file : new File( corpusdir ).listFiles()) {
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
%>
<div id="graph2" class="graph" oncontextmenu="return false" style="position:relative; height: 90%; ">
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
<div id="graph3" class="graph" oncontextmenu="return false" style="position:relative; height: 90%; ">
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
  var data = <% sigma2( term, -1 ); %>;
  var graph = new sigmot("graph2", data ); //
})(); 
(function () {
  var data = <% sigma( term, -1 ); %>;
  var graph = new sigmot("graph3", data ); //
})(); 
  </script>
  <% } %>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>