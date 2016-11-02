<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="

java.io.InputStream,
java.io.InputStreamReader,
java.io.IOException,
java.io.PrintWriter,
java.io.Reader,
java.text.DecimalFormat,
java.text.NumberFormat,
java.util.Enumeration,
java.util.HashMap,
java.util.HashSet,
java.util.Locale,
java.util.List,
java.util.Map,
java.util.Properties,

site.oeuvres.muthovek.Dicovek,
site.oeuvres.muthovek.Dicovek.SimRow,
site.oeuvres.fr.Lexik

"%>
<%!
/** liste de corpus */
static Properties props;

/** Vector space */
private Dicovek veks;
/** All nodes fo edges  */
private HashMap<String,Integer> nodes;
/** Local nodes, explored  */
private HashSet<String> explored;
/**
 * Sort les relations entre siminymes
 */
private void siminyms( JspWriter out, String term, int vocab, int hits ) throws IOException
{
  if ( null == term || "".equals( term )) return;
  DecimalFormat df = (DecimalFormat)NumberFormat.getNumberInstance(Locale.ENGLISH);
  List<SimRow> sims = veks.sims( term, vocab );
  int i= 1;
  for ( SimRow row:sims ) {
    // normalement c’est le premier mot, on ne sort pas de relation
    // if ( row.term.equals(term) ) continue;
    out.print( "<tr><td>" );
    out.print( i );
    out.print( "</td><td>" );
    out.print( row.term );
    out.print( "</td><td>" );
    out.print( row.count );
    out.print( "</td><td>" );
    out.print( row.score );
    out.print( "</td></tr>" );
    if ( i++ >= hits) break;
  }
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
  List<SimRow> sims = veks.sims( term, vocab );
  int i= 1;
  explored.add( term );
  for ( SimRow row:sims ) {
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
}

%>
<%
request.setCharacterEncoding("UTF-8");
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Muthovek</title>
    <style>
body { padding: 2em; font-family: sans-serif; } 
    </style>
  </head>
  <body>
<%
if ( props == null ) {
  Reader reader = new InputStreamReader( application.getResourceAsStream("/corpus.properties"), "UTF-8");;
  props = new Properties();
  props.load(reader);
}
String corpus = request.getParameter("corpus");
if ( corpus == null) corpus = "zola";
if ( !props.containsKey( corpus )) corpus = "zola";

String context = application.getRealPath("/")+"/";

veks = (Dicovek)application.getAttribute( corpus );
if ( veks == null) {
  String glob = props.getProperty( corpus );
  if ( !glob.startsWith( "/" )) glob = context + glob; 
  int wing = 5;
  veks = new Dicovek(wing, wing, Lexik.STOPLIST, new PoorLem());
  out.print("<pre>");
  veks.walk( glob, new PrintWriter(out) );
  out.print("</pre>");
  application.setAttribute( corpus, veks );
}
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
%>
    <h1><%= props.get( corpus+".title" ) %></h1>
    <%
out.println("<p><b>Mots fréquents :</b> ");
out.println( veks.freqlist(true, 100) );
out.println("</p>");


    %>
    <form name="w">
      <label title="Where to search ">
      Corpus
      <select name="corpus">
        <option/>
      <% 
Enumeration e = props.propertyNames();
while ( e.hasMoreElements() ) {
  String key = (String) e.nextElement();
  if ( key.contains( "." ) ) continue;
  out.print("<option value=\"");
  out.print( key );
  out.print( '"' );
  if ( corpus.equals( key ) ) out.print( "\" selected=\"selected\"" );
  out.print(">");
  out.print( props.getProperty( key+".title" ) );
  out.print("</option>\n");  
}
      %>
      </select>
      <label title="Word to search">
      term <input type="search" name="term" value="<%=term%>"/>
      </label>
      <input type="submit"/>
      <br/>
      <label title="Theshold of vectors to serch in">
        vocabulary
        <input size="4" name="vocab" value="<%=vocab%>"/>
      </label>
      <label title="Number of siminymes">
        hits
        <input size="2" name="hits" value="<%=hits%>"/>
      </label>
      
    </form>
    <%
  out.println("<p><b>Cooccurrents :</b> ");
  out.println( veks.coocs( term, 30, true ) );
  out.println("</p>");
  %>
    <table class="sortable" align="center">
      <caption>Siminymes</caption>
      <tr>
        <th>Rank</th>
        <th>Term</th>
        <th>Count</th>
        <th>Proximity</th>
      </tr>
      <% siminyms( out, term, vocab, hits ); %>
    </table>
    <%  %>
    <pre><% 
out.println("Source\tTarget\tWeight\tType");      
edges( out, term, vocab, 30); 
      %>
    
    </pre>
    <pre><% 
out.println("Id\tcount");
for ( Map.Entry<String, Integer> entry : nodes.entrySet() ) {
  out.print( entry.getKey() );
  out.print("\t");
  out.print( entry.getValue() );
  out.print("\n");
}
      %>
    
    </pre>
    <%  %>
    <script src="Sortable.js">//</script>
  </body>
</html>