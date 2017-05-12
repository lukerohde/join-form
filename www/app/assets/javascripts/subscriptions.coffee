# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

subscription_helper_ready = ->
  Stripe.setPublishableKey($('meta[name="stripe-key"]').attr('content'))
  newSession = localStorage.getItem('scrollYPos') == null
  subscription.setupForm()
  subscription.autoSubmitOnPrefill()
  if ($('[type="date"]').prop('type') != 'date' )
    $('[type="date"]').datepicker()
  $('.date-picker').datepicker(dateFormat: 'yy-mm-dd')
  subscription.goToStep() unless newSession
  $("#subscription_search_time_zone_offset").val(new Date().getTimezoneOffset())

subscription =
  autoSubmitOnPrefill: ->
    if (window.location.search.indexOf('auto_submit=true')>-1)
      $('#new_subscription')[0].submit()

  goToStep: ->
    noticeHeight = 0
    if $('#notice')?
      noticeHeight = $('#notice').outerHeight()
      $('.subscription_header').css('margin-top', noticeHeight);

    step = $("#step").data('step')
    if step? && step != "thanks" && localStorage.getItem('scrollYPos')?

      # Go to last scroll position
      window.scrollTo(0, localStorage.getItem('scrollYPos'))
      # show the next step
      if $("#" + step)?
        $("#" + step).show()

        # scroll down, allowing room for the notice
        top = $('#' + step).offset().top
        top = top - noticeHeight
        top = 0 if top < 0

        $('html, body').animate({
          scrollTop: top
        }, 1000)

    localStorage.removeItem('scrollYPos')

  swapSubmitLabel: ->
    temp = $('#subscription_submit').prop('value')
    $('#subscription_submit').prop('value', $('#subscription_submit').data('label'))
    $('#subscription_submit').data('label', temp)

  setupForm: ->
    $('#new_subscription, .edit_subscription').submit ->

      subscription.swapSubmitLabel()
      $('#subscription_submit').attr('disabled', true)
      localStorage.setItem('scrollYPos', window.scrollY);
      if $('#subscription_pay_method').val() == "CC"
        if $('#subscription_card_number').length
            subscription.processCard()
            false
          else
            true
      else
        true

  processCard: ->
    card =
      number: $('#subscription_card_number').val()
      cvc: $('#subscription_ccv').val()
      expMonth: $('#subscription_expiry_month').val()
      expYear: $('#subscription_expiry_year').val()
    Stripe.createToken(card, subscription.handleStripeResponse)

  handleStripeResponse: (status, response) ->
    if status == 200
      $('#subscription_stripe_token').val(response.id)
      $('#new_subscription, .edit_subscription')[0].submit()
    else
      $('#stripe_error').text(response.error.message)
      $('#subscription_submit').attr('disabled', false)
      subscription.swapSubmitLabel()

setupSignature = ->
  if $('#signature_vector').val()?
    if $('#signature_vector').val() != ""
      @sig = $('.edit_subscription, #new_subscription').signaturePad({drawOnly:true, displayOnly: true, lineTop: 68})
      @sig.regenerate($('#signature_vector').val())
    else
      @sig = $('.edit_subscription, #new_subscription').signaturePad({drawOnly:true, lineTop: 68, validateFields: false})

@payMethod =
  init: (refresh_path) ->
    $('#subscription_frequency').on 'change', payMethod.refreshForm
    $('#subscription_pay_method').on 'change', payMethod.refreshForm
    payMethod.refreshPath = refresh_path
    #payMethod.setDeductionDateVisibility()
    return

  refreshForm: ->
    form = $('#subscription-form')
    $('#pay-method-fields').css 'opacity', 0.5
    $.ajax
      type: 'POST'
      url: payMethod.refreshPath
      data: form.serialize()
      dataType: 'html'
      success: (response) ->
        $('#pay-method-fields').html response
        $('#pay-method-fields').css 'opacity', 1
        return
    return

  # setDeductionDateVisibility: ->
  #   freq = $('#subscription_frequency').val()
  #   pm = $('#subscription_pay_method').val()
  #   if pm == 'PRD' or [
  #       'Q'
  #       'H'
  #       'Y'
  #     ].indexOf(freq) != -1
  #     $('#deduction-date-container').addClass 'collapse'
  #     false
  #   else
  #     $('#deduction-date-container').removeClass 'collapse'
  #     true

subscription_ready = ->
  if $('meta[name="js-context"]').attr('controller') == "subscriptions"
    subscription_helper_ready()
    setupSignature()

$(document).ready(subscription_ready);
