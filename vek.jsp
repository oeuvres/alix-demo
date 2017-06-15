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

private void sigma( List<SimRow> sims, boolean stop ) throws IOException
{
  int edgemax = 500;
  
  TermDic dic = veks.dic();
  HashMap<Integer, int[]> nodes = new HashMap<Integer, int[]>();
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
  for ( SimRow source:sims ) {
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


/**
 * Sort les relations entre siminymes
 */
private void sims( List<SimRow> sims, int hits, final String href, boolean stop ) throws IOException
{
  int stopoffset = veks.stopoffset;
  TermDic dic = veks.dic();
  DecimalFormat df = new DecimalFormat("0.0000", DecimalFormatSymbols.getInstance(Locale.FRANCE));

  int i= 1;
  printer.println( "<table class=\"sortable\">" );
  printer.println( "<caption>Siminymes (cosine) </caption>" );
  printer.println( "<tr>" );
  // printer.println( "  <th>Rank</th>" );
  printer.println( "  <th>Term</th>" );
  printer.println( "  <th>Count</th>" );
  printer.println( "  <th>Distance</th>" );
  printer.println( "</tr>" );
  
  for ( SimRow row:sims ) {
    if ( stop && row.code < stopoffset ) continue;
    // normalement c’est le premier mot, on ne sort pas de relation
    // if ( row.term.equals(term) ) continue;
    printer.print( "<tr>" );
    // printer.print( "<td>"+i+"</td>" );
    printer.print( "<td class=\"term\">" );
    String term = dic.label( row.code );
    printer.print( "<a href=\""+href+term+"\">" );
    printer.print( term );
    printer.print( "</a>" );
    printer.print( "</td><td align=\"right\">" );
    printer.print( dic.count( row.code ) );
    printer.print( "</td><td>" );
    // printer.print( df.format( row.score ) );
    printer.print( row.score );
    printer.println( "</td></tr>" );
    if ( i++ >= hits) break;
  }
  printer.println( "</table>" );
}

private void coocs( String term, final int hits, final String href ) throws IOException
{
  int stopoffset = veks.stopoffset;
  TermDic dic = veks.dic();
  IntVek vek = veks.vek( term );
  if ( vek == null ) return;
  Pair[] coocs = vek.toArray();
  printer.println( "<table class=\"sortable\">" );
  printer.println( "<caption>Cooccurrents</caption>" );
  printer.println( "<tr>" );
  // printer.println( "  <th>Rank</th>" );
  printer.println( "  <th>Term</th>" );
  printer.println( "  <th>Count</th>" );
  printer.println( "</tr>" );
  int size = coocs.length;
  boolean first = true;
  String w;
  int rank = 1;
  for ( int j = 0; j < size; j++ ) {
    if ( coocs[j].key < stopoffset ) continue;
    printer.println( "<tr>" );
    // printer.println( "  <td>"+rank+"</td>" );
    w = dic.label( coocs[j].key );
    printer.print( "  <td class=\"term\">" );
    printer.println( "<a href=\""+href+w+"\">"+w+"</a></td>" );
    printer.println( "  <td align=\"right\">"+coocs[j].value+"</td>" );
    printer.println( "</tr>" );
    if ( ++rank > hits ) break;
  }
  printer.println( "</table>" );
}



%>
<%@include file="vekshare.jsp" %>
<%

int left = -5;
// try { left = Integer.parseInt( request.getParameter( "left" ) ); } catch (Exception e) {}
// if ( left < -30 && left > 0) left = -5;

int right = 5;
// try { right = Integer.parseInt( request.getParameter( "right" ) ); } catch (Exception e) {}
// if ( right < 0 || right > 30) right = 5;

form( corpusdir, corpus, term );
if ( corpus != null && !corpus.isEmpty() ) {
  String corpuskey = corpus;
  // charger le corpus en mémoire s’il n’y est pas
  veks = (Dicovek)application.getAttribute( corpus );
  // test freshness
  if ( veks != null && new File( corpusdir, corpus ).lastModified() > veks.modified() ) veks = null;
  if ( veks != null && (left != veks.left || right != veks.right) ) veks = null;  
  if ( veks == null) {
    String glob = corpusdir + corpus;
    if ( new File( glob ).isDirectory() ) glob = glob+"/*";
    veks = new Dicovek( left, right );
    out.print("<pre>");
    veks.walk( glob, new PrintWriter(out) );
    out.print("</pre>");
    veks.prune(5); // suppress vectors for unfrequent words
    application.setAttribute( corpuskey, veks );
  }

}
if ( veks == null );
else if ( term.isEmpty() ) { 
  out.println("<p><b>Mots fréquents :</b> ");
  out.println( veks.freqlist( true, 100 ) );
  out.println("</p>");
}
else { 
  int limit = 30;
  out.println("<table class=\"page\"><tr  height=\"100%\">");
  String href = "?corpus="+corpus+"&amp;term=";
  out.println("<td class=\"col\">");
  coocs( term, limit, href );
  out.println("</td>");
  List<SimRow> sims = veks.sims( term );
  if ( sims != null ) {
    boolean stopfilter = true;
    out.println( "<td class=\"col\">" );
    sims( sims, limit, href, stopfilter ); 
    out.println( "</td>" );
    out.println( "<td class=\"col\" width=\"70%\">" );
    out.println( "<style> #graph { min-height: 700px; } </style>" );
    graphdiv( "graph" );
    out.print("<script> (function () { var data = ");
    sigma( sims, stopfilter );
    out.print("\n var graph = new sigmot( 'graph', data ); \n })(); ");
    out.println("</script>");
    out.println("</td>");
  }
  out.println("</tr></table>");
  out.println( "<p>“Siminymes de siminymes”, réseau de similarité cosine à deux niveaux.</p>" );
  out.println("<iframe style=\"border: none;\" name=\"vek2\" src=\"vek2.jsp?iframe=1&amp;corpus="+corpus+"&amp;term="+term+"\""
   +" width=\"99%\" height=\"90%\"></iframe>");
}
  %>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>