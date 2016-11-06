<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
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
  if ( catalog != null ) return catalog;
  catalog = new LinkedHashMap<String,String[]>();
  BufferedReader buf = new BufferedReader( 
    new InputStreamReader(
      pageContext.getServletContext().getResourceAsStream( "/catalog.csv" ), 
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
/** Output a text selector for  */
static void seltext( PageContext pageContext, String value ) throws IOException
{
  JspWriter out = pageContext.getOut();
  String selected = " selected=\"selected\" ";
  String sel = "";
  if (value == null) sel = selected;
  String[] cells = null;
  out.println("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+sel+">Choisir un texte…</option>");
  for ( String code: catalog.keySet(  ) ) {
    cells = catalog.get( code );
    if ( code.equals( value ) ) sel = selected;
    else sel = "";
    out.println("<option value=\""+code+"\""+sel+">"+cells[1]+". "+cells[2]+"</option>");
  }
}
%>
<%
// instantiate catalog
catalog( pageContext );
%>