extends "res://tests/test_case.gd"

const Entries := preload("res://core/text/entries.gd")


func test_hours_are_read_in_their_usual_forms() -> void:
	check_eq(Entries.minutes_from_text("9"), 540, "9")
	check_eq(Entries.minutes_from_text("9h"), 540, "9h")
	check_eq(Entries.minutes_from_text("9 h 30"), 570, "9 h 30")
	check_eq(Entries.minutes_from_text("09:30"), 570, "09:30")
	check_eq(Entries.minutes_from_text(" 17H05 "), 1025, "17H05, avec des espaces autour")
	check_eq(Entries.minutes_from_text("9h5"), 545, "9h5")
	check_eq(Entries.minutes_from_text("0"), 0, "minuit")
	check_eq(Entries.minutes_from_text("24"), 1440, "24 h")


func test_unreadable_hours_are_refused() -> void:
	for text in ["", "h30", "neuf heures", "9h60", "25", "24h01", "9:3:0", "-9", "+9", "123", "9h123"]:
		check_eq(Entries.minutes_from_text(text), -1, "« %s »" % text)


func test_ambiguous_hours_are_refused_rather_than_guessed() -> void:
	# « 9,5 » voudrait dire 9 h 30 et « 9.30 » aussi : aucune des deux n'est devinée.
	check_eq(Entries.minutes_from_text("9,5"), -1, "9,5")
	check_eq(Entries.minutes_from_text("9.30"), -1, "9.30")


func test_hours_are_written_the_way_they_are_read() -> void:
	check_eq(Entries.text_from_minutes(540), "9 h 00", "9 h")
	check_eq(Entries.text_from_minutes(1025), "17 h 05", "17 h 05")
	for minutes in [0, 15, 540, 765, 1439, 1440]:
		check_eq(Entries.minutes_from_text(Entries.text_from_minutes(minutes)), minutes, "aller-retour de %d min" % minutes)


func test_sums_are_read_in_their_usual_forms() -> void:
	check_eq(Entries.cents_from_text("2000"), 200000, "2000")
	check_eq(Entries.cents_from_text("2 000"), 200000, "2 000")
	check_eq(Entries.cents_from_text("2 000,50 €"), 200050, "2 000,50 € avec une espace fine")
	check_eq(Entries.cents_from_text("2000.5"), 200050, "2000.5")
	check_eq(Entries.cents_from_text("1834,07"), 183407, "1834,07")
	check_eq(Entries.cents_from_text("0"), 0, "zéro")
	check_eq(Entries.cents_from_text("2000,"), 200000, "virgule sans centimes")


func test_unreadable_sums_are_refused() -> void:
	for text in ["", "deux mille", ",50", "2000,505", "2.000", "1.234,56", "-100", "+100", "12345678", "20 00 a"]:
		check_eq(Entries.cents_from_text(text), -1, "« %s »" % text)


func test_sums_are_written_the_way_they_are_read() -> void:
	check_eq(Entries.text_from_cents(200000), "2000", "somme ronde")
	check_eq(Entries.text_from_cents(200050), "2000,50", "avec des centimes")
	check_eq(Entries.text_from_cents(183407), "1834,07", "centimes à un chiffre")
	for cents in [0, 7, 100, 183407, 200000, 999999999]:
		check_eq(Entries.cents_from_text(Entries.text_from_cents(cents)), cents, "aller-retour de %d c" % cents)
