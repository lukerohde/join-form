Deferred payment feature
========================

Initial Request
---------------

Hey Luke,

Do you think it’s possible for us to have **a join form with two options** for the HKCTU?

(1)    The upfront $300/year option; and
(2)    The $11.70 per week where a worker **self-nominates their start date** for the deduction of fees

Cheers,
Godfrey Moase

From: Stanley 秘書處 永旺 [mailto:stanley.ho@hkctu.org.hk]
Sent: Tuesday, 21 February 2017 6:26 PM
Subject: Re: Union Member Referral Agreement

Dear Godrey

We want to add two more details :

1, We also want to provide weekly deduction $11.70 union fee for Hong Kong backpackers to choose;
2, Clarification on backpackers **pay union fee when they start to work**. Vice versa.

Thanks for your help~~~

in Solidarity,
STANLEY

Risks
-----

1. Self nominating a payment start date is different from paying union fees when they start work
2. Deferred payment date is different from preferred reoccuring deduction date, mitigation options a) two dates b) no pro-rata charging c) pro-rata disabled for joins forms that allow deferal
3. Does frequency and start date appear in a step before the payment step, or does it live with in the payment step, mitigation - all goes in the payment step
4. Does the system start with some sensible payment defaults, which the user can override - mitigation: yes (maybe stop using drop downs)
5. Pro-rata first payment might be hard, mitigation - don't do it
6. Pro-rata may or may not be wanted, mitigation - don't do it
7. Integrating the $300 less paid dues logic might be hard - Ignore it.


### Part 1 - Get it done
When there are no custom questions in the custom questions it does not show TESTED.  In the payment step the user is presented with a reasonable set of default options, in the following order - pay method (DD or CC), Frequency (fortnightly), deduction date (starting today unless DD, then next working day).  If the user changes pay method, frequency or deduction date the payment step is refreshed, keeping their input where possible, but only presenting valid input choices - for instance, it doesn't make sense to have today as the first day of payment for direct debit.  Choosing a weekly payment doesn't allow deferred payment beyond a week.  Choosing a fortnightly option doesn't allow deferring beyond more than a fortnight.  Choosing a monthly payment doesn't allow selecting a date beyond one month. Choosing an quarterly or annual payment option may not show any deferred payment option at all.  Choosing a pay roll deduction option doesn't show the frequency or deferred payment options.  Choosing dd release, allows frequency and shows a notice explaining payment will start after dd release.  Changing a frequency will change the amount payable now. Defering a payment will defer the charge to the user and will validate the credit card.  Subscription description will show somewhere sensible.  Translations for all text changes (including subscription to misc elaneous rename, deduction_date).

### Part 2 - Finesse
The system will not refresh the page between steps, instead will progressively expand the form.  The form designer shall be able to customize which contact details fields will be shown, including skipping the address field.  The system shall have an optional 'I'd like to join the join checkbox' which expands the regular payment options field..  When 'I'd like to join the union' is unticked, and the signature is enabled, then the user can sign.  The form designer can change the label on the submit button when the user is not joining, and when the user is joining.  The system has a counter towards a goal that the form designer can set.  The form designer can set an offset for the counter.  The counter is shown when setup along side prominent sharing options.  Optionally turn off address.

The form designer can customize the form with additional questions.  These questions can be placed at the start of the form or before payment.  

TEST PLAN
-- Subscription step skipped without custom questions DONE
---- unit test step method DONE
---- controller test, address to paymethod DONE
-- Subscription step not skipped with custom questions DONE
---- unit test step method DONE
---- controller test, address to custom questions DONE
-- When address is not required then it skips appropriately
---- when misc required, to miscellaneous  
---- when misc not required, to pay method
-- On paymethod step the user is shown a reasonable set of defaults options TESTED
---- Australian Bank account TESTED
---- fortnightly TESTED
---- Deduction starting next working day TESTED

-- Payment method validation fails without frequency TESTED
-- Payment method validation fails without deduction date
-- Payment method validation fails with invalid deduction date for weekly frequency
-- Payment method validation fails with invalid deduction date for fortnightly frequency
-- Payment method validation fails with invalid deduction date for monthly frequency
-- Payment method validation fails with invalid deduction date for quarterly frequency
-- Payment method validation fails with invalid deduction date for yearly frequency
-- Payment method validation passes with deduction date deferred
-- Credit card validated rather than charged with deduction date is deferred
-- deduction is not shown when disabled
-- deduction date can be enabled for the join form
-- deduction date is disabled by default on new join forms
-- Changing the pay_method to credit card reloads the form allowing immediate deduction
-- Changing the pay_method to australian bank account reloads the form not allowing immediate deduction, setting an invalid field value to tomorrow
-- Direct Debit Release validates without deduction date
-- Payroll
-- Payroll deduction valids without deduction date and frequency
-- Changing between credit card and direct persist what fields can be persisted.
