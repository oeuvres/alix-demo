<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
/*
  | <a href="collocs.jsp?" title="Locutions et collocations">Phraséologie</a>

*/
String htpars="";
if ( request.getParameter( "bibcode" ) != null && !request.getParameter( "bibcode" ).isEmpty(  ))
  htpars += "&amp;bibcode="+request.getParameter( "bibcode" );
%>
<nav class="menu">
  <a href=".">▲ Alix</a>
  | <a href="freq.jsp?<%= htpars %>" title="Fréquences lexicales">Fréquences</a>
  | <a href="wordcloud.jsp?<%= htpars %>&amp;frantext=on" title="Nuage de mots">Nuage</a>
  | <a href="comp.jsp?<%= htpars %>" title="Tableaux lexicaux comparatifs">Comparaison</a>
  | <a href="grep.jsp?<%= htpars %>" title="Concordance et cooccurrences">Concordance</a>
  | <a href="vek.jsp" title="Vecteurs lexicaux">Siminymes</a>
  | <a href="lem.jsp?">Lemmatiseur</a>
  | <a href="reps.jsp?<%= htpars %>">Récurrences</a>
  | <a href="gn.jsp?<%= htpars %>" title="Adjectifs ante/post posés">Adjectifs</a>
</nav>