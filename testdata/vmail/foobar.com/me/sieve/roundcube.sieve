require ["copy","date","relational","vacation"];
# rule:[Urlaub]
if allof (currentdate :zone "+0100" :value "ge" "iso8601" "2015-10-26T10:00:00+01:00", currentdate :zone "+0100" :value "le" "iso8601" "2015-10-26T12:00:00+01:00")
{
	vacation :addresses "me@thores-zimmer.de" :subject "Out of Office notification" "BIN GRAD NICHT VERFÜGBAR DU SACK!";
}
# rule:[copy to me2@]
if true
{
	redirect :copy "me2@thores-zimmer.de";
	keep;
}
