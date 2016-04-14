# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

subscription_helper_ready = ->
  Stripe.setPublishableKey($('meta[name="stripe-key"]').attr('content'))
  subscription.setupForm()
  subscription.autoSubmitOnPrefill()

subscription =
  autoSubmitOnPrefill: ->
    if (window.location.search.indexOf('auto_submit=true')>-1)
      $('#new_subscription')[0].submit()

  setupForm: ->
    $('#new_subscription, .edit_subscription').submit ->
      $('input[type=submit]').attr('disabled', true)
      if $('#subscription_pay_method').val() == "Credit Card" # TODO figure out how to localize
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
      $('input[type=submit]').attr('disabled', false)

@pay_method_change = (e) ->
  $("#edit_credit_card").toggle (e.value is "Credit Card")
  $("#edit_au_bank_account").toggle (e.value is "Australian Bank Account")

pay_method_ready = ->
  $('#edit_credit_card').hide()
  $('#edit_au_bank_account').hide()
  switch $('#subscription_pay_method').val()
    when 'Credit Card'
      $('#edit_credit_card').show()
    when 'Australian Bank Account'
      $('#edit_au_bank_account').show()
  return
     
$(document).on('turbolinks:load', pay_method_ready);
$(document).on('turbolinks:load', subscription_helper_ready);

