<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.InputStream,
java.util.Scanner,

java.util.LinkedHashMap,
java.io.BufferedReader,
java.io.InputStreamReader,
java.io.IOException,
java.nio.charset.StandardCharsets,
java.nio.file.Files,

alix.fr.Occ,
alix.fr.Tokenizer,
alix.fr.Lexik,
alix.fr.Tag,
alix.fr.WordEntry,
alix.util.TermDic

" %>
<%!
/** Catalog of available texts, data wil be unique for a jsp page, but copied for each jsp */
static LinkedHashMap<String,String[]> catalog;
/** Get catalog, populate it if empty */
static LinkedHashMap<String,String[]> catalog( PageContext pageContext ) throws IOException
{
  String force = pageContext.getRequest().getParameter( "force" );
  if ( catalog != null && force == null) return catalog;
  catalog = new LinkedHashMap<String,String[]>();
  BufferedReader buf = new BufferedReader( 
    new InputStreamReader(
      pageContext.getServletContext().getResourceAsStream( "/WEB-INF/catalog.csv" ), 
      StandardCharsets.UTF_8
    )
  );
  buf.readLine(); // skip first line
  String[] cells;
  String l;
  while ((l = buf.readLine()) != null) {
    if (l.charAt( 0 ) == '#' ) continue;
    cells = l.split(";");
    catalog.put( cells[0], new String[] { cells[1], cells[2], cells[3]} );
  }
  buf.close();
  return catalog;
}
/** Output a text selector for texts */
static void seltext( PageContext pageContext, String value ) throws IOException
{
  JspWriter out = pageContext.getOut();
  String selected = " selected=\"selected\" ";
  String sel = "";
  if (value == null) sel = selected;
  String[] cells = null;
  out.println("<option value=\"\" "+sel+">Choisir un texte…</option>");
  for ( String code: catalog.keySet(  ) ) {
    cells = catalog.get( code );
    if ( code.equals( value ) ) sel = selected;
    else sel = "";
    out.println("<option value=\""+code+"\""+sel+">"+cells[1]+". "+cells[2]+"</option>");
  }
}
/** Get text from a code */
static String text( PageContext pageContext, String code ) 
{
  String[] line = catalog.get( code );
  if ( line == null ) return null;
  InputStream stream = pageContext.getServletContext().getResourceAsStream( line[0] );
  if ( stream == null ) return null;
  Scanner sc = new Scanner( stream, "UTF-8" );
  sc.useDelimiter("\\A");
  String text = sc.next();
  sc.close();
  return text;
}

/**
 * Charger un dictionnaire avec les mots d’un texte, comportement général
 */
public TermDic gparse( String text ) throws IOException {
  TermDic dic = new TermDic();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  short cat;
  while ( toks.word( occ ) ) {
    if ( occ.tag.isVerb() || occ.tag.code() == Tag.ADJ ) {
      dic.inc( occ.lem, occ.tag.code() );
    }
    else dic.inc( occ.orth, occ.tag.code() );
  }
  return dic;
}

/**
 * Récupérer un dictionnaire par identifiant, comportement général
 */
public TermDic gdic( PageContext pageContext, final String code ) throws IOException 
{
  ServletContext application = pageContext.getServletContext();
  String att = "M"+code;
  TermDic dico = (TermDic)application.getAttribute( att );
  if ( dico != null ) return dico;
  String[] bibl = catalog.get( code );
  // texte inconnu
  if ( bibl == null ) return null;
  /*
  String home = application.getRealPath("/");
  String filepath = home + "/textes/" + bibl[1];
  Path path =  Paths.get( filepath );
  new String( Files.readAllBytes( path ), StandardCharsets.UTF_8 )
  */
  // http://web.archive.org/web/20140531042945/https://weblogs.java.net/blog/pat/archive/2004/10/stupid_scanner_1.html
  dico = gparse(  new Scanner( application.getResourceAsStream( bibl[0] ), "UTF-8" ).useDelimiter("\\A").next() );
  application.setAttribute( att, dico );
  return dico;
}


%>
<%
// instantiate catalog
catalog( pageContext );
%>