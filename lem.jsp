<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.io.StringReader" %>
<%@ page import="java.io.Writer" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.nio.file.Path" %>
<%@ page import="java.nio.file.Paths" %>

<%@ page import="org.apache.lucene.analysis.AlixReuseStrategy" %>
<%@ page import="org.apache.lucene.analysis.Analyzer" %>
<%@ page import="org.apache.lucene.analysis.AnalyzerReuseControl" %>
<%@ page import="org.apache.lucene.analysis.TokenStream" %>
<%@ page import="org.apache.lucene.analysis.Tokenizer" %>
<%@ page import="org.apache.lucene.analysis.core.WhitespaceTokenizer" %>
<%@ page import="org.apache.lucene.analysis.standard.StandardTokenizer" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.CharTermAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.FlagsAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.OffsetAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.PositionIncrementAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.PositionLengthAttribute" %>

<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.analysis.FrLemFilter" %>
<%@ page import="alix.lucene.analysis.FrPersnameFilter" %>
<%@ page import="alix.lucene.analysis.FrTokenizer" %>
<%@ page import="alix.lucene.analysis.LocutionFilter" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsLemAtt" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsOrthAtt" %>
<%@ page import="alix.web.*" %>


<%!

static class LemAnalyzer extends Analyzer
{

  @Override
  protected TokenStreamComponents createComponents(String fieldName)
  {
    final Tokenizer source = new FrTokenizer();
    TokenStream result = new FrLemFilter(source);
    // result = new LocutionFilter(result);
    // result = new FrPersnameFilter(result);
    return new TokenStreamComponents(source, result);
  }

}


  public static void vertical(final String text, final Analyzer analyzer, final Writer out) throws IOException
  {
    TokenStream stream = analyzer.tokenStream("stats", text);
    vertical(stream, out);
    analyzer.close();
  }
  public static void vertical(final TokenStream stream, final Writer out) throws IOException
  {

    // get the CharTermAttribute from the TokenStream
    CharTermAttribute term = stream.addAttribute(CharTermAttribute.class);
    CharsOrthAtt orth = stream.addAttribute(CharsOrthAtt.class);
    FlagsAttribute flags = stream.addAttribute(FlagsAttribute.class);
    CharsLemAtt lem = stream.addAttribute(CharsLemAtt.class);
    /*
    OffsetAttribute offsets = stream.addAttribute(OffsetAttribute.class);
    PositionIncrementAttribute posInc = stream.addAttribute(PositionIncrementAttribute.class);
    PositionLengthAttribute posLen = stream.addAttribute(PositionLengthAttribute.class);
    */
    
    try {
      stream.reset();
      // print all tokens until stream is exhausted
      while (stream.incrementToken()) {
        out.write("<tr>\n");
        out.write("  <td>");
        JspTools.escape(out, term);
        out.write("</td>\n");
        out.write("  <td>");
        JspTools.escape(out, orth);
        out.write("</td>\n");
        out.write("  <td>"+Tag.name(flags.getFlags())+"</td>\n");
        out.write("  <td>");
        JspTools.escape(out, lem);
        out.write("</td>\n");
        out.write("</tr>\n");
      }
      
      stream.end();
    }
    finally {
      stream.close();
    }
  }


%>
<% 
request.setCharacterEncoding("UTF-8"); 
Part part = null;
String contentType = request.getContentType();
if ("POST".equalsIgnoreCase(request.getMethod()) && (contentType != null) && contentType.startsWith("multipart/form-data")) {
  part = request.getPart("file");
}
// send as csv
if (part != null) {
  response.setContentType(Mime.tsv.type);
  String fileName = JspTools.getFileName(part);
  fileName = fileName.replaceAll("\\.[^.]+$", ".tsv");
  response.setHeader("Content-Disposition", "attachment; filename=\""+fileName+"\"");
  BufferedReader in = new BufferedReader(new InputStreamReader(part.getInputStream(), StandardCharsets.UTF_8));
  Analyzer analyzer = new LemAnalyzer();
  TokenStream stream = analyzer.tokenStream("stats", in);

  {
    CharTermAttribute term = stream.addAttribute(CharTermAttribute.class);
    CharsOrthAtt orth = stream.addAttribute(CharsOrthAtt.class);
    FlagsAttribute flags = stream.addAttribute(FlagsAttribute.class);
    CharsLemAtt lem = stream.addAttribute(CharsLemAtt.class);
    /*
    OffsetAttribute offsets = stream.addAttribute(OffsetAttribute.class);
    PositionIncrementAttribute posInc = stream.addAttribute(PositionIncrementAttribute.class);
    PositionLengthAttribute posLen = stream.addAttribute(PositionLengthAttribute.class);
    */
    
    try {
      stream.reset();
      // print all tokens until stream is exhausted
      while (stream.incrementToken()) {
        out.append(term);
        out.append("\t");
        out.append(orth);
        out.append("\t");
        out.append(Tag.name(flags.getFlags()));
        out.append("\t");
        out.append(lem);
        out.append("\n");
      }
      
      stream.end();
    }
    finally {
      stream.close();
    }
  }
  
  
  analyzer.close();

  out.close();
}




%>
<!DOCTYPE html>
<html>
  <head>
    <title>Le lemmatiseur du pauvre</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <style>
    </style>
  </head>
  <body>
    <%@include file="menu.jsp" %>
    <article>
      <h1><a href="">Lemmatiser</a></h1>
      <!-- 
      <p>
Les vers passent en général très mal dans un lemmatiseur, car les majuscules ne coïncident pas avec
la ponctuation, si bien qu’ils produisent beaucoup de faux noms propres, et autres erreurs imprévisibles.
En réaction, ce lemmatiseur adopte des stratégies plus simples, mais plus soignées sur les dictionnaires et le découpage des mots.
Pour une forme graphique, le principe initial est de donner le lemme le plus fréquent.
Obligatoirement, l’étiquetage sera fautif sur les homographes les moins fréquents,
ainsi “est” est toujours considérée comme l’auxilliaire “être”.
Mais comme ce sont justement des mots moins fréquents, 
cela produit moins d’erreurs que des stratégies plus savantes avec des algorithmes.
L’autre avantage, c’est que ces erreurs sont déterministes, elles dépendent de dictionnaire maîtrisés,
et non pas d’un entraînement sur des corpus de textes non précisés.
Il en résulte que la sortie est plus fiable pour y appuyer des jeux de règles, ou des entraînements
statistiques, pouvant corriger les erreurs restantes si elles nuisaient à une applications particulière.
</p>
 -->
      <%
      String text = request.getParameter("text");
      %>
      <form method="post" action="?" enctype="multipart/form-data">
        <label for="file">Soumettre un fichier</label>
        <input type="file" name="file" />
        <button name="submit" type="submit">Télécharger</button>
      </form>
        <%
        /*
        (Unknown) voir uniquement les erreurs
        boolean unknown = !(request.getParameter( "unknown" ) == null);
        String url = request.getParameter( "url" ); if (url == null) url="";
        
       if ( !"".equals( url ) ) {
         try {
           Scanner scan = new Scanner(  new URL( url ).openStream(), "UTF-8" );
           scan.useDelimiter("\\A"); 
           text = scan.next();
           scan.close();
         }
         catch (Exception e) {
           out.print( "<p>"+url+" Impossible de retirer le texte souhaité.</p>" );
           text = null;
         }
       }
        */
      if ( text == null) text = "La Beauté\n\n"
      + "Je suis belle, ô mortels! comme un rêve de pierre,\n"
      + "Et mon sein, où chacun s'est meurtri tour à tour,\n"
      + "Est fait pour inspirer au poète un amour\n"
      + "Éternel et muet ainsi que la matière.\n"
      + "\n"
      + "Je trône dans l'azur comme un sphinx incompris;\n"
      + "J'unis un cœur de neige à la blancheur des cygnes;\n"
      + "Je hais le mouvement qui déplace les lignes,\n"
      + "Et jamais je ne pleure et jamais je ne ris.\n"
      + "\n"
      + "Les poètes, devant mes grandes attitudes,\n"
      + "Que j'ai l'air d'emprunter aux plus fiers monuments,\n"
      + "Consumeront leurs jours en d'austères études;\n"
      + "\n"
      + "Car j'ai, pour fasciner ces dociles amants,\n"
      + "De purs miroirs qui font toutes choses plus belles:\n"
      + "Mes yeux, mes larges yeux aux clartés éternelles!\n";
      %>
      <form method="post" action="?">
        <label for="text">Ou bien tester du texte</label>
        <textarea name="text" style="width: 100%; height: 10em; " onchange="this.form.method='post'; "><%=text%></textarea>
        <button name="submit" type="submit">Tester</button>
      </form>
      <section class="table2">
       <table id="legend" class="lem" width="500">
         <caption>Catégories lexicales : légende</caption>
         <thead>
          <th>Numéro</th>
          <th>Code</th>
          <th>Nom</th>
          <th>Description</th>
         </thead>
         <tbody>
           <%
           int parentLast = 0;
           for (Tag tag : Tag.values()) {
             final int parent = tag.parent;
             if (parent != parentLast) {
               out.println("<tr class=\"empty\"><td> </td><td> </td><td> </td><td> </td></tr>");
               parentLast = parent;
             }
             out.println("<tr>");
             out.print("<td>");
             out.print(Integer.toHexString(tag.flag));
             out.println("</td>");
             out.print("<td>");
             out.print(tag.name());
             out.println("</td>");
             out.print("<td>");
             out.print(tag.label);
             out.println("</td>");
             out.print("<td>");
             out.print(tag.desc);
             out.println("</td>");
             out.println("</tr>");
           }
           %>
         </tbody>
       </table>
      <table class="lem">
        <thead>
          <tr>
            <th>Graphie</th>
            <th>Forme</th>
            <th>Catégorie</th>
            <th>Lemme</th>
          </tr>
        </thead>
        <tbody>
      <%
       vertical(text, new LemAnalyzer(), out);
      
      %>
        </tbody>
       </table>
       </div>
     </article>
  </body>
 </html>
