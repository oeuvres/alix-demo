<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%> 
<%@ page import="
java.io.File,
java.nio.file.Paths,
java.util.Comparator,
java.util.Locale,


org.apache.lucene.analysis.Analyzer,
org.apache.lucene.document.Document,
org.apache.lucene.index.IndexReader,
org.apache.lucene.index.DirectoryReader,
org.apache.lucene.index.Term,
org.apache.lucene.misc.HighFreqTerms,
org.apache.lucene.misc.HighFreqTerms.*,
org.apache.lucene.misc.TermStats,
org.apache.lucene.search.IndexSearcher,
org.apache.lucene.search.Query,
org.apache.lucene.search.TermQuery,
org.apache.lucene.search.ScoreDoc,
org.apache.lucene.search.TopDocs,
org.apache.lucene.store.FSDirectory,site.oeuvres.lucene.MoreLikeThis,site.oeuvres.lucene.XmlAnalyzer" %>
<%
String lucdir = application.getRealPath( File.separator )+"/WEB-INF/lucene";
IndexReader reader = DirectoryReader.open( FSDirectory.open(Paths.get(lucdir)) );
IndexSearcher searcher = new IndexSearcher( reader );
Analyzer analyzer = new XmlAnalyzer();
Comparator<TermStats> termcomp = new TotalTermFreqComparator();
// Comparator<TermStats> termcomp = new DocFreqComparator();
TermStats[] terms = HighFreqTerms.getHighFreqTerms( reader, 200, "text", termcomp);
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Chapitre, navigateur de romans</title>
    <style>
p.p { text-align: justify; text-indent: 1em; margin: 0; }
    </style>
  </head>

  <body>
    <article style="width: 60ex; margin-left: auto; margin-right: auto; ">
	<%
String pdoc = request.getParameter("doc");
Document doc;
Query query;
if ( pdoc == null || "".equals( pdoc )) {
  for (int i=0; i<reader.maxDoc(); i++) {    
    doc = reader.document(i);
    if (doc == null) continue;
    out.println("<li>");
    out.print("<a href=\"?doc=");
    out.print(doc.get("href"));
    out.print("\">");
    out.print(doc.get("date"));
    out.print(", <i>");
    out.print(doc.get("title"));
    out.print("</i>, « ");
    out.print(doc.get("head"));
    out.println(" »</li>");
  }

}
else {
	query = new TermQuery( new Term( "href", pdoc ) );
	TopDocs topdocs = searcher.search( query, 1 );
	int docNum = topdocs.scoreDocs[0].doc;
	doc = searcher.doc( docNum );
	out.print("<h1><a href=\"?\">◀</a> "+doc.get("title")+"</h1>");
	out.print("trouvemoi");
	
	MoreLikeThis mlt = new MoreLikeThis( reader );
	mlt.setMinTermFreq(0);
	mlt.setMinDocFreq(0);
	mlt.setMaxDocFreqPct(10);
	mlt.setLower(true);
	mlt.setMaxQueryTerms(100);
	mlt.setFieldNames(new String[]{"text"});
	// normalement les tags sont tombés, on a que les termes ?
	// mlt.setAnalyzer(analyzer);
	out.print("<p>");
	boolean first = true;
	for (String s: mlt.retrieveInterestingTerms( docNum )) {
	  if ( first ) first = false;  
	  else out.print( ", " );
	  out.print(s);
	}
	out.print("</p>");
	
	
	Query qmlt = mlt.like( docNum );
	// out.print("<p>"+qmlt+"</p>");
	TopDocs results = searcher.search(qmlt, 20);
	ScoreDoc[] hits = results.scoreDocs;
	int totalHits = results.totalHits;
	
	int max = Math.min(results.totalHits, 20);
	for (int i = 0; i < max; i++) {
	  Document mltdoc = searcher.doc(hits[i].doc);
	  out.println("<li>");
	  out.print(hits[i].score+" — ");
	  out.print("<a href=\"?doc=");
	  out.print(mltdoc.get("href"));
	  out.print("\">");
	  out.print(mltdoc.get("date"));
	  out.print(", <i>");
	  out.print(mltdoc.get("title"));
	  out.print("</i>, « ");
	  out.print(mltdoc.get("head"));
	  out.println(" »</a></li>");
	}
	out.print(doc.get("html"));
}
	%>
	</article> 
  </body>

</html>
<%
reader.close();
%>
