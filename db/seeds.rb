# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
union = Union.new( name: "Natioanl Union of Workers", www: "nuw.org.au", short_name: "NUW" )
union.save(validate: false)
user = Person.create!( email: "admin@nuw.org.au", password: "temptemp", password_confirmation: "temptemp", first_name: "Admin", union: union )
user.update!(invited_by: user, authorizer: user) # invite self for the sake of looking like a user

unions = Union.create([
{ name: "Victorian Trades Hall Council", short_name: "VTHC", www: "vthc.org.au", type: "Union"},
{ name: "Civil Air", short_name: "Civil Air", www: "securing.work", type: "Union"},
{ name: "Professionals Australia", short_name: "APESMA", www: "securing.work", type: "Union"},
{ name: "Independent Education Union of Australia", short_name: "IEUA", www: "securing.work", type: "Union"},
{ name: "Australian Workers' Union", short_name: "AWU", www: "securing.work", type: "Union"},
{ name: "Victorian Psychologists Association Incorporated", short_name: "VPA Inc", www: "securing.work", type: "Union"},
{ name: "National Tertiary Education Union", short_name: "NTEU", www: "securing.work", type: "Union"},
{ name: "New South Wales Nurses and Midwives' Association", short_name: "NSWNMA", www: "securing.work", type: "Union"},
{ name: "Australian Maritime Officers Union", short_name: "AMOU", www: "securing.work", type: "Union"},
{ name: "Medical Scientists Association of Victoria", short_name: "MSAV", www: "securing.work", type: "Union"},
{ name: "Australasian Meat Industry Employees Union", short_name: "AMIEU", www: "securing.work", type: "Union"},
{ name: "Community and Public Sector Union - SPSF Group", short_name: "CPSU_SPSF", www: "securing.work", type: "Union"},
{ name: "Flight Attendants Association of Australia - National Division", short_name: "FAAA_National", www: "securing.work", type: "Union"},
{ name: "Construction, Forestry, Mining and Energy Union", short_name: "CFMEU", www: "securing.work", type: "Union"},
{ name: "Australian Writers' Guild", short_name: "AWG", www: "securing.work", type: "Union"},
{ name: "Association of Hospital Pharmacists", short_name: "AHP", www: "securing.work", type: "Union"},
{ name: "Shop Distributive and Allied Employees Association", short_name: "SDA", www: "securing.work", type: "Union"},
{ name: "Pilot Association for Virgin Australia Group", short_name: "VIPA", www: "securing.work", type: "Union"},
{ name: "Funeral and Allied Industries Union of NSW", short_name: "F&AI", www: "securing.work", type: "Union"},
{ name: "Communications, Electrical and Plumbing Union of Australia", short_name: "CEPU", www: "securing.work", type: "Union"},
{ name: "Transport Workers Union of Australia", short_name: "TWU", www: "securing.work", type: "Union"},
{ name: "Union of Christmas Island Workers", short_name: "UCIW", www: "securing.work", type: "Union"},
{ name: "Australian Licenced Aircraft Engineers Association", short_name: "ALAEA", www: "securing.work", type: "Union"},
{ name: "Australian Services Union", short_name: "ASU", www: "securing.work", type: "Union"},
{ name: "Australian Manufacturing Workers Union", short_name: "AMWU", www: "securing.work", type: "Union"},
{ name: "Blind Workers Union of Victoria", short_name: "BWU", www: "securing.work", type: "Union"},
{ name: "Maritime Union of Australia", short_name: "MUA", www: "securing.work", type: "Union"},
{ name: "Textile, Clothing and Footwear Union of Australia", short_name: "TCFUA", www: "securing.work", type: "Union"},
{ name: "Flight Attendants' Association of Australia - International", short_name: "FAAA_International", www: "securing.work", type: "Union"},
{ name: "Club Managers Association Australia", short_name: "CMAA", www: "securing.work", type: "Union"},
{ name: "Media, Entertainment & Arts Alliance", short_name: "MEAA", www: "securing.work", type: "Union"},
{ name: "Western Australian Prison Officers\' Union of Workers", short_name: "WAPOU", www: "securing.work", type: "Union"},
{ name: "Australian Professional Footballers` Association", short_name: "APFA", www: "securing.work", type: "Union"},
{ name: "Australian Education Union", short_name: "AEU", www: "securing.work", type: "Union"},
{ name: "United Firefighters Union of Australia", short_name: "UFU", www: "securing.work", type: "Union"},
{ name: "Rail, Tram and Bus Union", short_name: "RTBU", www: "securing.work", type: "Union"},
{ name: "Community and Public Sector Union - PSU Group", short_name: "CPSU_PSU", www: "securing.work", type: "Union"},
{ name: "Australian & International Pilots Association", short_name: "AIPA", www: "securing.work", type: "Union"},
{ name: "Australian Institute of Marine and Power Engineers", short_name: "AIMPE", www: "securing.work", type: "Union"},
{ name: "Australian Salaried Medical Officers Federation", short_name: "ASMOF", www: "securing.work", type: "Union"},
{ name: "Finance Sector Union", short_name: "FSU", www: "securing.work", type: "Union"},
{ name: "Breweries & Bottleyards Employees Industrial Union of Workers", short_name: "BBEIUW", www: "securing.work", type: "Union"},
{ name: "United Voice", short_name: "UV", www: "securing.work", type: "Union"},
{ name: "Police Federation of Australia", short_name: "PFA", www: "securing.work", type: "Union"},
{ name: "Australian Nursing & Midwifery Federation", short_name: "ANMF", www: "securing.work", type: "Union"},
{ name: "Health Services Union", short_name: "HSU", www: "securing.work", type: "Union"}
])
unions.each {|u| u.save!(validate: false)}
