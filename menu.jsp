<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String htpars="";
if ( request.getParameter( "bibcode" ) != null && !request.getParameter( "bibcode" ).isEmpty(  ))
  htpars += "&amp;bibcode="+request.getParameter( "bibcode" );
%>
<nav class="menu">
  <a href=".">▲ Alix</a>
  | <a href="freq.jsp?<%= htpars %>" title="Fréquences lexicales">Fréquences</a>
  | <a href="wordcloud.jsp?<%= htpars %>" title="Nuage de mots">Nuage</a>
  | <a href="comp.jsp?<%= htpars %>" title="Tableaux lexicaux comparatifs">Comparaison</a>
  | <a href="grep.jsp?<%= htpars %>" title="Concordance et cooccurrences">Concordance</a>
  | <a href="collocs.jsp?<%= htpars %>" title="Locutions et collocations">Phraséologie</a>
  | <a href="lem.jsp?">Lemmatiseur</a>
  | <a href="grep.jsp?<%= htpars %>" title="Adjectifs ante/post posés">Adjectifs</a>
</nav>