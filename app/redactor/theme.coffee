define ->
  getPageClassName = (objectId) ->
    "geenio-redactor-theme-#{objectId}"

  applyTheme = ({theme,objectId}) ->
    className = "js-redactorTheme-#{objectId}"
    styleEl = $(".#{className}")
    if styleEl.size() is 0
      styleEl = $("<style class='#{className}'/>").appendTo $('head')
    styleText = """
      .#{getPageClassName(objectId)} .gn-redactor-text h1 {
        color: #{theme.color.header};
        font-family: #{theme.font.header};
      }

      .#{getPageClassName(objectId)} .gn-redactor-text div, 
      .#{getPageClassName(objectId)} .gn-redactor-text p   {
        color: #{theme.color.content};
        font-family: #{theme.font.content};
      }

      .#{getPageClassName(objectId)}{
        background-color: #{theme.color.background};
      }

      .#{getPageClassName(objectId)} .gn-redactor-svg-container svg{
        fill: #{theme.color.fill};
        stroke: #{theme.color.border};
      }

      .#{getPageClassName(objectId)} .js-withBorder{
        border-color: #{theme.color.border};
      }
    """
    styleEl.text styleText

  {getPageClassName,applyTheme}
