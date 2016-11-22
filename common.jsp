<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.InputStream,
java.util.Scanner,

java.util.LinkedHashMap,
java.io.BufferedReader,
java.io.InputStreamReader,
java.io.IOException,
java.nio.charset.StandardCharsets,
java.nio.file.Files
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
/** Output a text selector for texts */
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
%>
<%
// instantiate catalog
catalog( pageContext );
%>