<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%>
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
java.util.Enumeration,
java.util.HashMap,
java.util.HashSet,
java.util.Locale,
java.util.List,
java.util.Map,
java.util.Properties,

alix.sqlite.Dicovek,
alix.sqlite.Dicovek.SimRow,
alix.util.IntVek,
alix.util.IntVek.Pair,
alix.fr.Lexik

"%>
<%!

/** Vector space */
private Dicovek veks;

/**
 * Parcourir les cooccurrents
 */
private void sigma( JspWriter out, String term ) throws IOException
{
  boolean stop = true;
  if ( Lexik.isStop( term ) ) stop = false;
  if ( null == term || "".equals( term )) return;
  DecimalFormat df = new DecimalFormat("0.0000", DecimalFormatSymbols.getInstance(Locale.FRANCE));
  List<SimRow> sims = veks.sims( term, -1 );
  if ( sims == null ) return;
  // collect infos on all nodes
  HashMap<Integer, String> nodes = new HashMap<Integer, String>();
  // output edges
  out.print( "  edges: [" );
  int edge = 1;
  int edgemax = 500;
  int isim = 1; // index of sim
  int bysim = 50;
  
  for ( SimRow row:sims ) {
    IntVek vector = veks.vector( row.code );
    if ( vector == null ) continue; // possible ?
    Pair[] coocs = vector.toArray();
    // loop on coocs, 10x ?
    int lastedge = edge;
    int max = bysim - isim;
    if ( max < 0 ) max = 0;
    max += 10;
    for ( int i=0; i < max; i++ ) {
      
    }
    
    
    if ( isim == 1 ) {
      nodes.put( row.code, "root" );
    }
    else {
      nodes.put( row.code, "sim" );
    }
    isim++;
    if ( edge >= edgemax ) break;
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
    veks = new Dicovek( -wing, wing );
    out.print("<pre>");
    veks.walk( glob, new PrintWriter(out) );
    out.print("</pre>");
    application.setAttribute( corpus, veks );
  }

}

%>
<script>
(function () { var data =
  <% 
  sigma( out, term ); 
  %>
  
})();
</script>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>