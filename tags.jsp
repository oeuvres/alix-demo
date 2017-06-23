<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.net.URL,
java.text.DecimalFormat,
java.util.Scanner,

alix.fr.Lexik,
alix.fr.Tag,
alix.fr.Tokenizer,alix.util.Occ" %>
<%@include file="common.jsp" %>
<%
  
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Proportions d'étiquettes</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <style>
    </style>
  </head>
  <body>
    <article>
      <h1><a href=".">Alix</a> : <a href="">Catégories grammaticales, proportions</a></h1>
      <%
        String[] taglist = { "SUB", "VERB", "SUB/VERB", "VERBaux", "VERBsup", "ADJ", "ADV", "NAME",
          "PROpers", "DETposs", "DETart", "CONJcoord", "CONJsubord"
          , "PREP", "ADVneg", "PROrel", "ADVquant", "PROdem", "DETdem"
          // ADVtemp<7 476>, DETindef<6 906>, PROindef<5 232>, ADVindef<5 060>, 
          // DETprep<4 215>, DETnum<3 855>, EXCL<3 687>, ADVplace<3 277>, NUM<2 675>, 
           // ADVinter<2 437>, DETinter<726>, PROposs<720>
          };
      %>
      <table class="sortable">
        <tr>
          <th>Auteur</th>
          <th>Titre</th>
          <%
            for ( String label: taglist ) {
            out.print("<th>");
            out.print(label);
            out.println("</th>");
          }
          %>
        <tr>
      <%
        // boucler sur le catalogue
      for ( String bibcode: catalog.keySet(  ) ) {
        String[] bibl = catalog.get( bibcode );
        out.print( "<tr>" );
        out.print("<td>");
        out.print( bibl[1]);
        out.println("</td>");
        out.print("<td>");
        out.print( bibl[2]);
        out.println("</td>");
        // lister
        boolean first = true;
        DicFreq tags = dic( pageContext, bibcode, "T");
        long occs = tags.occs();
        for ( String label: taglist) {
          out.print("<td>");
          if ( label.equals( "SUB/VERB" )) {
        out.print( 1F*tags.count( "SUB") / tags.count( "VERB") );
          }
          else {
        out.print(ppmdf.format( 1000000F * tags.count( label) / occs ) );
          }
          out.print("</td>");
        }
        out.print( "</tr>" );
      }
      %>
      </table>
     </article>
    <script src="lib/Sortable.js">//</script>
  </body>
 </html>
