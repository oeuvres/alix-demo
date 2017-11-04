<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%><%!

private void sigma( List<SimRow> sims, boolean stop ) throws IOException
{
  int edgemax = 500;
  
  DicFreq dic = veks.dic();
  HashMap<Integer, int[]> nodes = new HashMap<Integer, int[]>();
  // do not repeat root -> cooc
  HashSet<IntPair> done = new HashSet<IntPair>();
  IntPair test = new IntPair(); // pair test

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
    nodes.get( row.target )[1]+=row.spec;
    nodes.get( row.key )[1]+=row.spec;
    printer.println( "    { id:'e"+edge+"', source:'n"+row.target+"', target:'n"+row.key+"', size:"+row.spec+" }, "
    +"// "+dic.label( row.target )+" "+cooc );
    edge++;
    // ROOT -> cooc
    test.set( row.source, row.key );
    if ( done.contains( test ) ) continue;
    done.add( new IntPair(test) );
    nodes.get( row.source )[1]+=row.spec;
    nodes.get( row.key )[1]+=row.spec;
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
  DicFreq dic = veks.dic();
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
  DicFreq dic = veks.dic();
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
}%>
<%@include file="vekshare.jsp" %>
<body>
  <%@include file="menu.jsp"%>
  <p style="margin:2em 1em 0 1em; width: 80ex;">Une idée initiale de Marianne Reboul, un programme d’expériences conçu par Olivier Gallet, développé par Frédéric Glorieux, 
  sur un corpus sélectionnné par Alexandre Gefen.</p>
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
  veks = (DicVek)application.getAttribute( corpus );
  // test freshness
  if ( veks != null && new File( corpusdir, corpus ).lastModified() > veks.modified() ) veks = null;
  if ( veks != null && (left != veks.left || right != veks.right) ) veks = null;  
  if ( veks == null) {
    String glob = corpusdir + corpus;
    if ( new File( glob ).isDirectory() ) glob = glob+"/*";
    veks = new DicVek( left, right );
    out.print("<pre>");
    veks.walk( glob, new PrintWriter(out) );
    out.print("</pre>");
    veks.prune(5); // suppress vectors for unfrequent words
    application.setAttribute( corpuskey, veks );
  }

}
if ( veks == null );
else if ( term.isEmpty() ) { 
  
  DicFreq dic = veks.dic();
  /*
  Cloud cloud = Cloud.cloud( dic, 200, cloudfilter );
  cloud.doLayout();
  out.println("<div id=\"cloud\" style=\"margin-left\">");
  out.println( cloud.html() );
  out.println("</div>");
  */
  out.println( "<script> var div=document.getElementById('cloud'); a = div.getElementsByTagName('a'); ");
  out.println( "for ( var i = 0; i < a.length; ++i ) a[i].href='?corpus="+corpus+"&term='+a[i].innerText;</script>" );
  
  out.println("<p><b>Mots fréquents :</b> ");
  out.println( veks.freqlist( true, 100 ) );
  out.println("</p>");
}
else { 
  int limit = 30;
  out.println("<table class=\"page\"><tr  height=\"100%\">");
  String href = "?corpus="+corpus+"&amp;term=";
  out.println("<td lass=\"col\">");
  coocs( term, limit, href );
  out.println( "</td>" );
  List<SimRow> sims = veks.sims( term );
  if ( sims != null ) {
    boolean stopfilter = true;
    out.println("<td class=\"col\">");
    sims( sims, limit, href, stopfilter ); 
    out.println( "</td>" );
    out.println( "<td class=\"col\" width=\"70%\" rowspan=\"2\">" );
    out.println( "<style> #graph { min-height: 700px; } </style>" );
    graphdiv( "graph" );
    out.print("<script> (function () { var data = ");
    sigma( sims, stopfilter );
    out.print("\n var graph = new sigmot( 'graph', data ); \n })(); ");
    out.println("</script>");
  }
  out.println("</td>");
  out.println("</tr>");
  out.println("<tr>");
  out.println("<td colspan=\"2\" rowspan=\"2\">");
  out.println( "<p class=\"doc\">" );
  out.println( " Les siminymes sont des mots rapprochés par un algorithme de similarité (ici, cosine)."
    + " A l’entrée, un automate parcourt le corpus, s’arrête sur chaque mot, "
    + " et collecte son contexte (5 mots avant, 5 mots après)."
    + " Ces sacs de cooccurrents sont tous comparés deux à deux, ce qui permet pour chaque mot,"
    + " de proposer une liste ordonnée de mots qui seraient proches."
    + " Il ne s’agit pas d’un dictionnaire, le programme ignore tout des définitions, mais il révèle qu’il y a souvent"
    + " une correspondance entre le sens d’un mot et son contexte d’emploi. Le mot <a href=\"?corpus=1890&amp;term=France\">France</a>"
    + " sera ainsi rapproché d’<i>Irlande</i>, ou <i>Provence</i>, mais aussi, et ce ne sont pas des erreurs,"
    + " de <i>vogue</i> ou de <i>Sorbonne</i>, à cause des expressions <i>en vogue</i> ou <i>en Sorbonne</i>."
    + " <i>En</i> est un cooccurrent très fréquent des noms de pays, mais entre aussi dans beaucoup de locutions,"
    + " c’est le mot qui a pesé le plus dans la relation de similarité. "
    + " Le réseau à droite est centré sur le mot de la requête, en <b>rouge</b>."
    + " Les mots en <b>bleu-violet</b> sont les “siminymes”, ou voisins."
    + " Les mots en <b>gris</b> sont les cooccurrents qui pèsent le plus dans le calcul de similarité."
    + " L’intention est de donner au lecteur des indices pour comprendre pourquoi le calcul rapproche des mots"
    + " (les cooccurrents grammaticaux ne sont pas montrés pour ne pas trop emmêler l’écheveau)."
    + " Si l’on revient à l’exemple du mot <i>France</i>, il est aussi rapproché de <i>littérature</i> et <i>poésie</i>, à cause des collocations fréquentes : "
    + " <i>histoire de France, de la littérature, de la poésie</i>…"
    + " La taille des nœuds et des relations est significative de leur poids dans les similarités"
    + " (mais n’est pas représentative du poids dans le texte)."
  );
  out.println( "</p>" );
  out.println("</td>");
  out.println("</tr>");
  out.println("<tr>");
  // out.println("<td/>");
  // out.println("<td/>");
  out.println("<td valign=\"bottom\">");
  out.println( "<p class=\"doc\" style=\"margin-left: auto;\">“Siminymes de siminymes”, réseau de similarité cosine à deux niveaux."
   +" <br/>Sur le mot central de la requête (rouge) l’argorithme recherche automatiquement des mots similaires, les enfants directs (violet)."
   +" Le moteur est relancé sur chacun de ces mots, les petits-enfants (bleu), pouvant reconnecter le réseau à des nœuds déjà présents,"
   +" ou bien ouvrir de nouvelles branches. "
   +" La taille des nœuds est relative à la fréquence globale du mot dans le corpus. "
   +"</p>" );
  out.println("</td>");
  out.println("</tr>");
  out.println("</table>");
  out.println("<iframe style=\"border: none;\" name=\"vek2\" src=\"vek2.jsp?iframe=1&amp;corpus="+corpus+"&amp;term="+term+"\""
   +" width=\"99%\" height=\"90%\"></iframe>");
}
%>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>