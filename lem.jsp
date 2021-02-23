<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%@ page import="java.io.IOException" %>
<%@ page import="java.io.StringReader" %>
<%@ page import="java.io.Writer" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.nio.file.Path" %>

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
    TokenStream stream = analyzer.tokenStream("stats", new StringReader(text));
    vertical(text, stream, out);
    analyzer.close();
  }
  public static void vertical(final String text, final TokenStream stream, final Writer out) throws IOException
  {

    // get the CharTermAttribute from the TokenStream
    CharTermAttribute term = stream.addAttribute(CharTermAttribute.class);
    CharsLemAtt lem = stream.addAttribute(CharsLemAtt.class);
    CharsOrthAtt orth = stream.addAttribute(CharsOrthAtt.class);
    OffsetAttribute offsets = stream.addAttribute(OffsetAttribute.class);
    FlagsAttribute flags = stream.addAttribute(FlagsAttribute.class);
    PositionIncrementAttribute posInc = stream.addAttribute(PositionIncrementAttribute.class);
    PositionLengthAttribute posLen = stream.addAttribute(PositionLengthAttribute.class);
    
    try {
      stream.reset();
      // print all tokens until stream is exhausted
      while (stream.incrementToken()) {
        out.write("<tr>\n");
        out.write("  <td>"+term+"</td>\n");
        out.write("  <td>"+orth+"</td>\n");
        out.write("  <td>"+Tag.label(flags.getFlags())+"</td>\n");
        out.write("  <td>"+lem+"</td>\n");
        out.write("</tr>\n");
      }
      
      stream.end();
    }
    finally {
      stream.close();
    }
  }


%>
<% request.setCharacterEncoding("UTF-8"); %>
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
      <h1><a href=".">Alix</a> : <a href="">Lemmatisation</a></h1>
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
      String text = request.getParameter( "text" );
      %>
      <form method="post" action="?">
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
        <textarea name="text" style="width: 100%; height: 10em; " onchange="this.form.method='post'; "><%=text%></textarea>
        <button type="submit">Envoyer</button>
      </form>
      <table class="lem">
        <tr>
          <th>Graphie</th>
          <th>Forme</th>
          <th>Catégorie</th>
          <th>Lemme</th>
        </tr>
      <%
      vertical(text, new LemAnalyzer(), out);
      %>
       </table>

     </article>
  </body>
 </html>
