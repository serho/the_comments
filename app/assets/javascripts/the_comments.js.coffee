# ERROR MSG BUILDER
@error_text_builder = (errors) ->
  error_msgs = ''
  for error in errors
    error_msgs += "<p><b>#{ error }</b></p>"
  error_msgs

# FORM CLEANER
@clear_comment_form = (form) ->
  form.find('.error_notifier', '[role=new_comment_form], .comments_tree').hide()
  form.find("input[name='comment[title]']").val('')
  form.find("textarea[name='comment[raw_content]']").val('')

# NOTIFIER
@comments_error_notifier = (form, text) ->
  form.children('.error_notifier').empty().hide().append(text).show()

# JUST HELPER
@unixsec = (t) -> Math.round(t.getTime() / 1000)

# HIGHTLIGHT ANCHOR
@highlight_anchor = ->
  hash = document.location.hash
  if hash.match('#comment_')
    $(hash).addClass 'highlighted'

$ ->
  window.tolerance_time_start = unixsec(new Date)

  comments_block = '[role=comments_block]'
  comment_forms  = $("[role=new_comment_form], .reply_comments_form")
  tolerance_time = $('[data-comments-tolarance-time]').first().data('comments-tolarance-time')

  # Button Click => AJAX Before Send
  submits = $('[role=new_comment_form] input[type=submit], .reply_comments_form input[type=submit]')
  
  submits.on 'click', (e) ->
    button    = $ e.target
    form      = button.parents('form').first()
    time_diff = unixsec(new Date) - window.tolerance_time_start

    if tolerance_time && (time_diff < tolerance_time)
      delta  = tolerance_time - time_diff
      error_msgs = error_text_builder(["Please wait #{delta} secs"])
      comments_error_notifier(form, error_msgs)
      return false

    $('.tolerance_time').val time_diff
    button.hide()
    true

  # AJAX ERROR
  comment_forms.on 'ajax:error', (request, response, status) ->
    form = $ @
    $('input[type=submit]', form).show()
    error_msgs = error_text_builder(["Server Error: #{response.status}"])
    comments_error_notifier(form, error_msgs)

  # COMMENT FORMS => SUCCESS
  comment_forms.on 'ajax:success', (request, response, status) ->
    form = $ @
    block = form.parents(comments_block)

    $('input[type=submit]', form).show()

    if typeof(response) is 'string'
      anchor = $(response).find('.comment').attr('id')
      clear_comment_form form
      form.find('.parent_id').val('')
      form.find('[role=new_comment_form]').fadeIn()
      tree = form.parent().siblings('.nested_set')
      tree = block.find('ol.comments_tree') if tree.length is 0
      tree.append(response)
      document.location.hash = anchor
    else
      error_msgs = error_text_builder(response.errors)
      comments_error_notifier(form, error_msgs)

  # NEW ROOT BUTTON
  $('#new_root_comment').on 'click', ->
    $('.reply_comments_form').hide()
    $('.parent_id').val('')
    $('[role=new_comment_form]').fadeIn()
    false

  # REPLY BUTTON
  $('.reply_link').on 'click', ->
    link    = $ @
    comment = link.parents('.comment')
    block = link.parents(comments_block)

    comment_forms.hide()
    form = block.find('[role=new_comment_form]').clone().removeAttr('id').addClass('reply_comments_form')

    comment_id = comment.data('comment-id')
    block.find('.parent_id', form).val comment_id

    comment.siblings('.form_holder').html(form)
    form.fadeIn()
    false

$ ->
  # ANCHOR HIGHLIGHT
  highlight_anchor()

  $(window).on 'hashchange', ->
    $('.comment.highlighted').removeClass 'highlighted'
    highlight_anchor()