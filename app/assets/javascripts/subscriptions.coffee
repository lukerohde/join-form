# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

subscription_helper_ready = ->
  Stripe.setPublishableKey($('meta[name="stripe-key"]').attr('content'))
  subscription.setupForm()
  subscription.autoSubmitOnPrefill()
  if ($('[type="date"]').prop('type') != 'date' )
    $('[type="date"]').datepicker()
  subscription.goToStep()
  
subscription =
  autoSubmitOnPrefill: ->
    if (window.location.search.indexOf('auto_submit=true')>-1)
      $('#new_subscription')[0].submit()

  goToStep: ->
    step = $("#step").data('step')
    if step != "contact_details" && localStorage.getItem('scrollYPos')? 
      
      # Go to last scroll position
      window.scrollTo(0, localStorage.getItem('scrollYPos'))
      
      # show the next step
      $("#" + step).show()       
      
      # scroll down, allowing room for the notice
      top = $('#' + step).offset().top
      if $('#notice')? 
        top = top - $('#notice').outerHeight()
        top = 0 if top < 0 

      $('html, body').animate({ 
          scrollTop: top 
      }, 1000)

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

@pay_method_change = (e) ->
  $("#edit_credit_card").toggle (e.value is "CC")
  $("#edit_au_bank_account").toggle (e.value is "AB")

pay_method_ready = ->
  $('#edit_credit_card').hide()
  $('#edit_au_bank_account').hide()
  switch $('#subscription_pay_method').val()
    when 'CC'
      $('#edit_credit_card').show()
    when 'AB'
      $('#edit_au_bank_account').show()
  return
     
firefox_form_reset = ->
  $('#subscription_submit').attr('disabled', false)
  subscription.swapSubmitLabel()

$(document).on('turbolinks:load', pay_method_ready);
$(document).on('turbolinks:load', subscription_helper_ready);
$(window).unload firefox_form_reset