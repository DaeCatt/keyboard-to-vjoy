StringStartsWith(string, needle, caseSensitive := false) {
	return caseSensitive
		? needle == SubStr(string, 1, StrLen(needle))
		: needle = SubStr(string, 1, StrLen(needle))
}

StringEndsWith(string, needle, caseSensitive := false) {
	return caseSensitive
		? needle == SubStr(string, -StrLen(needle))
		: needle = SubStr(string, -StrLen(needle))
}

Clamp(num, min, max) {
	if (num < min) {
		return min
	}

	if (num > max) {
		return max
	}

	return num
}

Atan2(y, x) {
	return dllcall("msvcrt\atan2", "Double", y, "Double", x, "CDECL Double")
}