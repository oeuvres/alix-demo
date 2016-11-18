<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.InputStream,
java.io.PrintWriter,
java.util.Scanner,
java.util.List,
java.util.Map,
java.text.DecimalFormat,
java.text.DecimalFormatSymbols,

alix.util.TermDic,
alix.fr.Lexik,
alix.fr.LexikEntry,
alix.frana.GN
"%>
<%!

%>
<%@include file="common.jsp" %>
<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="UTF-8">
    <title>Adjectifs ante ou post posés</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <article>
      <h1><a href=".">Alix</a> : <a href="?">Adjectifs ante ou post posés</a></h1>
      <p>
Cette interface vise à étudier la position de l’adjectif autour de son substantif.
Un automate capture un groupe nominal restreint (déterminant, adjectifs, substantifs, adverbes adjectivaux),
sans propositions plus complexes. La précision de l’analyse automatique peut être testée en soumettant un
petit texte dans le formulaire, les résultats sont alors rendus sous la forme d’une concordance
de toutes les occurrences de groupes adjectivaux capturés.
L’intérêt de l’automate est de délivrer des statististiques plus globales sur les emplois ante et post posés,
tableau lexical que l’on obtient en sélectionnant un texte dans le corpus de cette installation.
Une concordance limitée à 2000 occurrences est livrée à la suite, pour se faire une meilleure idée de ce qui est capturé.
      </p>
      <%
      String text = request.getParameter( "text" );
      String ref = request.getParameter( "ref" );
      if (ref == null && text == null) 
        text =""
         +" Les soirs où, assis devant la maison sous le grand marronnier, autour de la table de fer, nous"
         +" entendions au bout du jardin, non pas le grelot profus et criard qui arrosait, qui étourdissait "
         +" au passage de son bruit ferrugineux, intarissable et glacé, toute personne de la maison qui le "
         +" déclenchait en entrant « sans sonner », mais le double tintement timide, ovale et doré de la clochette"
         +" pour les étrangers, tout le monde aussitôt se demandait : « Une visite, qui cela peut-il être ? » mais"
         +" on savait bien que cela ne pouvait être que M. Swann ; ma grand’tante parlant à haute voix, pour"
         +" prêcher d’exemple, sur un ton qu’elle s’efforçait de rendre naturel, disait de ne pas chuchoter ainsi ;"
         +" que rien n’est plus désobligeant pour une personne qui arrive et à qui cela fait croire qu’on est en train"
         +" de dire des choses qu’elle ne doit pas entendre ; et on envoyait en éclaireur ma grand’mère, toujours heureuse"
         +" d’avoir un prétexte pour faire un tour de jardin de plus, et qui en profitait pour arracher subrepticement"
         +" au passage quelques tuteurs de rosiers afin de rendre aux roses un peu de naturel, comme une mère qui, pour"
         +" les faire bouffer, passe la main dans les cheveux de son fils que le coiffeur a trop aplatis.";
       if ( text == null ) text = "";
       if ( !"".equals( text )) ref = null;
      %>
      <form id="seltext" name="seltext" method="get">
        <textarea name="text" style="width: 100%; height: 10em;"  placeholder="Copier/coller un texte"  
        onblur="this.form.method = 'post'; this.form.action = '?' "
        onclick="this.select()"
         ><%= text %></textarea>
      ou <select name="ref"  onchange="this.form.text.value = ''; this.form.method = 'get'; this.form.submit(); ">
          <% seltext( pageContext, ref ); %>
        </select>
        <button type="submit">Envoyer</button>
      </form>
      <%
TermDic dico = null;
while (true) {
  if ( ref == null ) break;
  String[] bibl = catalog.get( ref );
  // texte inconnu
  if ( bibl == null ) {
    out.println( "<p class=\"error\">"+ref+": texte inconnu de cette installation.</p>" );
    break;
  }
  InputStream stream = application.getResourceAsStream( bibl[0] );
  if ( stream == null ) {
    out.println( "<p class=\"error\">"+bibl[0]+": fichier introuvable sur cette installation.</p>" );
    break;
  }
  // conordance ?
  text = new Scanner( stream, "UTF-8" ).useDelimiter("\\A").next();
  
  String att = "A"+ref;
  dico = (TermDic)application.getAttribute( att );
  if ( dico != null ) break;
  GN gn = new GN( text );
  dico = gn.parse( );
  application.setAttribute( att, dico );
  break;
}      
if ( dico != null) {
    %>
      <table class="sortable">
        <tr>
          <th>N°</th>
          <th>Adjectif</th>
          <th title="Effectif antéposé">Antéposé</th>
          <th title="Effectif postposé">Postposé</th>
          <th title="Fréquence en “ppm” (partie par million)">Fréq./M.</th>
          <th>% Frantext</th>
        </tr>
    <%
    List<Map.Entry<String, int[]>> list = dico.entriesByCount();
    int limit = 200;
    int i = 1;
    float franfreq = 0;
    float myfreq;
    float bias;
    LexikEntry lexie = null;
    String orth;
    DecimalFormat biasdf = new DecimalFormat("# %");
    DecimalFormat dec0 = new DecimalFormat("#");
    long total = dico.occs();
    for ( Map.Entry<String, int[]> entry: list ) {
      orth = entry.getKey();
      out.println( "<tr>" );
      out.print( "<td>" );
      out.print( i );
      out.println( "</td>" );
      out.print( "<td>" );
      out.print( orth );
      out.println( "</td>" );
      out.print( "<td align=\"right\">" );
      out.print( entry.getValue()[TermDic.ICOUNT] );
      out.println( "</td>" );
      out.print( "<td align=\"right\">" );
      out.print( entry.getValue()[TermDic.ICOUNT2] );
      out.println( "</td>" );
      lexie = null;
      franfreq=0;
      myfreq = 1000000.0f*( entry.getValue()[TermDic.ICOUNT] + entry.getValue()[TermDic.ICOUNT2] ) / total;
      out.print( "<td align=\"right\">" );
      out.print( dec0.format( myfreq ) );
      out.println( "</td>" );
      lexie = Lexik.entry( orth );
      if ( lexie != null ) franfreq = lexie.lemfreq;
      bias =  myfreq / ( myfreq + franfreq );
      String bg = "bg" + Math.round( 10.0 * (2 * bias - 1) );
      out.println( "<td align=\"right\" class=\""+bg+"\">"+ biasdf.format( bias )+"</td>" );
      out.println( "</tr>" );
      
      if ( i++ >= limit ) break;
    }
      %>
      </table>
      <% 
}
if ( !text.isEmpty(  ) ) {
  GN gn = new GN( text );
  out.println( "    <table class=\"conc\">" );
  gn.parse( new PrintWriter(out), 2000 );
  out.println( "    </table>" );
}

%>
    </article>
    <script src="Sortable.js">//</script>
  </body>
</html>