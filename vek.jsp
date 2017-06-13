<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="

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
alix.sqlite.Dicovek.TextcatRow,
alix.fr.Lexik
"%>
<%!/** Vector space */
private Dicovek veks;
/** All nodes fo edges  */
private HashMap<String,Integer> nodes;
/** Local nodes, explored  */
private HashSet<String> explored;
/** Writer */
private JspWriter printer;

/**
 * Sort les relations entre siminymes
 */
private void siminyms( JspWriter out, String term, int hits, final String href, int vocab, boolean inter ) throws IOException
{
  boolean stop = true;
  if ( Lexik.isStop( term ) ) stop = false;
  if ( null == term || "".equals( term )) return;
  DecimalFormat df = new DecimalFormat("0.0000", DecimalFormatSymbols.getInstance(Locale.FRANCE));
  
  long start = System.nanoTime();

  List<CosineRow> sims = veks.sims( term, vocab, inter );
  if ( sims == null ) return;
  int i= 1;
  out.println( "<table class=\"sortable\" style=\"float:left\">" );
  if (inter) out.println( "<caption>Siminymes (cosine inter) "+((System.nanoTime() - start) / 1000000)+" ms.</caption>" );
  else out.println( "<caption>Siminymes (cosine) "+((System.nanoTime() - start) / 1000000)+" ms.</caption>" );
  out.println( "<tr>" );
  out.println( "  <th>Rank</th>" );
  out.println( "  <th>Term</th>" );
  out.println( "  <th>Count</th>" );
  out.println( "  <th>Distance</th>" );
  out.println( "</tr>" );
  
  for ( CosineRow row:sims ) {
    if ( stop && Lexik.isStop( row.term ) ) continue;
    // normalement c’est le premier mot, on ne sort pas de relation
    // if ( row.term.equals(term) ) continue;
    out.print( "<tr><td>" );
    out.print( i );
    out.print( "</td><td>" );
    out.print( "<a href=\""+href+row.term+"\">" );
    out.print( row.term );
    out.print( "</a>" );
    out.print( "</td><td align=\"right\">" );
    out.print( row.count );
    out.print( "</td><td align=\"right\">" );
    // out.print( df.format( row.score ) );
    out.print( row.score );
    out.println( "</td></tr>" );
    if ( i++ >= hits) break;
  }
  out.println( "</table>" );
}
/**
 * Sort les relations entre siminymes
 */
private void textcat( String term, int hits, final String href, int vocab ) throws IOException
{
  boolean stop = true;
  if ( Lexik.isStop( term ) ) stop = false;
  if ( null == term || "".equals( term )) return;
  List<TextcatRow> sims = veks.textcat( term );
  if ( sims == null ) return;
  int i= 1;
  printer.println( "<table class=\"sortable\" style=\"float:left\">" );
  printer.println( "<caption>Siminymes (Texcat)</caption>" );
  printer.println( "<tr>" );
  printer.println( "  <th>Rank</th>" );
  printer.println( "  <th>Term</th>" );
  printer.println( "  <th>Count</th>" );
  printer.println( "  <th>Distance</th>" );
  printer.println( "</tr>" );
  for ( TextcatRow row:sims ) {
    if ( stop && Lexik.isStop( row.term ) ) continue;
    // normalement c’est le premier mot, on ne sort pas de relation
    // if ( row.term.equals(term) ) continue;
    printer.print( "<tr><td>" );
    printer.print( i );
    printer.print( "</td><td>" );
    printer.print ( "<a href=\""+href+row.term+"\">" );
    printer.print( row.term );
    printer.print( "</a>" );
    printer.print( "</td><td align=\"right\">" );
    printer.print( row.count );
    printer.print( "</td><td align=\"right\">" );
    printer.print( row.score );
    printer.print( "</td></tr>" );
    if ( i++ >= hits) break;
  }
  printer.println( "</table>" );
}

private void edges( JspWriter out, String term, int vocab, int hits  ) throws IOException
{
  nodes = new  HashMap<String,Integer>();
  explored = new HashSet<String>();
  edges( out, term, vocab, hits, 1);
}
/**
 * Sort les relations entre siminymes
 */
private void edges( JspWriter out, String term, int vocab, int hits, int depth  ) throws IOException
{
  if ( null == term || "".equals( term )) return;
  DecimalFormat df = (DecimalFormat)NumberFormat.getNumberInstance(Locale.ENGLISH);
  List<CosineRow> sims = veks.sims( term, vocab );
  int i= 1;
  explored.add( term );
  for ( CosineRow row:sims ) {
    nodes.put( row.term, row.count );
    // normalement c’est le premier mot, on ne sort pas de relation, et on le garde en mémoire pour ne pas repasser
    if ( row.term.equals(term) ) {
      continue;
    }
    out.print( term );
    out.print( "\t" );
    out.print( row.term );
    out.print( "\t" );
    out.print( df.format( row.score * 100 ) );
    out.print( "\t" );
    out.print( "Directed" );
    out.print( "\n" );
    // le mot n’a pas encore été vu, et on veut approfondir
    if ( !row.term.equals(term) && !explored.contains( row.term ) && depth > 1 ) {
      edges( out, row.term, vocab, hits, depth-1);
    }
    if ( i++ >= hits) break;
  }
}%>
<%
request.setCharacterEncoding("UTF-8");
this.printer = out;

int left = -5;
try { left = Integer.parseInt( request.getParameter( "left" ) ); } catch (Exception e) {}
if ( left < -30 && left > 0) left = -5;

int right = 5;
try { right = Integer.parseInt( request.getParameter( "right" ) ); } catch (Exception e) {}
if ( right < 0 || right > 30) right = 5;

int depth = -1;
try { depth = Integer.parseInt( request.getParameter( "depth" ) ); } catch (Exception e) {}
if ( depth == 0 ) depth = -1;


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
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Dicovek</title>
    <style>
body { padding: 2em; font-family: sans-serif; } 
    </style>
  </head>
  <body>
    <h1><a href="?">Vecteurs de mots</a></h1>
<%
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
    application.setAttribute( corpuskey, veks );
  }

}
%>
    <form>
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
  out.print("<option");
  if ( key.equals( corpus ) ) out.print( " selected=\"selected\"" );
  out.print(">");
  out.print( key );
  out.print("</option>\n");  
}


%>
    </select>
    </label>
    <label title="Profondeur du vocabulaire à fouiller">Limite <input size="4" name="depth" value="<%= depth %>"/></label>
    Fenêtre
    <label>gauche <input size="2" name="left" value="<%= left %>"/></label>
    <label>droite <input size="2" name="right" value="<%= right %>"/></label>
    <label>Mot <input name="term" value="<%= term %>"/></label>
    <button type="submit">Chercher</button>
    </form>
    <%
if ( veks != null ) { 
  out.println("<p><b>Mots fréquents :</b> ");
  out.println( veks.freqlist(true, 100) );
  out.println("</p>");
}
if ( veks != null && !term.isEmpty() ) { 
  out.println("<p><b>Cooccurrents :</b> ");
  out.println( veks.coocs( term, 100, true ) );
  out.println("</p>"); %>
  <% 
  String href = "?corpus="+corpus+"&amp;depth="+depth+"&amp;right="+right+"&amp;right="+right+"&amp;term=";
  siminyms( out, term, 100, href, depth, true ); 
  siminyms( out, term, 100, href, depth, false ); 
  textcat( term, 100, href, depth );
}
  %>
    <%  %>
    <pre><% 
// out.println("Source\tTarget\tWeight\tType");      
// edges( out, term, vocab, 30); 
      %>
    
    </pre>
    <pre><% 
/*
out.println("Id\tcount");
for ( Map.Entry<String, Integer> entry : nodes.entrySet() ) {
  out.print( entry.getKey() );
  out.print("\t");
  out.print( entry.getValue() );
  out.print("\n");
}
*/
      %>
    
    </pre>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>