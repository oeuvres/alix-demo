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
java.util.Enumeration,
java.util.HashMap,
java.util.HashSet,
java.util.Locale,
java.util.List,
java.util.Map,
java.util.Properties,

alix.sqlite.Dicovek,
alix.sqlite.Dicovek.SimRow,
alix.fr.Lexik

"%>
<%!

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
  DecimalFormat df = (DecimalFormat)NumberFormat.getNumberInstance( Locale.FRANCE );
  List<SimRow> sims = veks.sims( term, vocab );
  if ( sims == null ) return;
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
    out.print(  df.format( row.score ) );
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
    <form>
    <label>Choisir un corpus 
    <select name="corpus" onchange="this.form.submit()">
      <option/>
<%
//lister les fichiers de corpus
for (final File file : new File( corpusdir ).listFiles()) {
  String key = file.getName();
  if ( key.startsWith( "." ) ) continue;
  if ( file.isDirectory() ) key += "/*";
  out.print("<option");
  if ( key.equals( corpus ) ) out.print( " selected=\"selected\"" );
  out.print(">");
  out.print( key );
  out.print("</option>\n");  
}


%>
    </select>
    <br/><label>Mot <input name="term" value="<%= term %>"/></label>
    </label>
    <br/><button type="submit">Chercher</button>
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
    int wing = 5;
    veks = new Dicovek( wing, wing );
    out.print("<pre>");
    veks.walk( glob, new PrintWriter(out) );
    out.print("</pre>");
    application.setAttribute( corpus, veks );
  }

}

%>
    <%
if ( veks != null ) { 
  out.println("<p><b>Mots fréquents :</b> ");
  out.println( veks.freqlist(true, 100) );
  out.println("</p>");
}
if ( veks != null && !term.isEmpty() ) { 
  out.println("<p><b>Cooccurrents :</b> ");
  out.println( veks.coocs( term, 30, true ) );
  out.println("</p>"); %>
  <table class="sortable" align="center">
  <caption>Siminymes</caption>
  <tr>
    <th>Rank</th>
    <th>Term</th>
    <th>Count</th>
    <th>Proximity</th>
  </tr>
  <% 
  siminyms( out, term, -1, 30 ); 
  out.println("</table>");
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