all:
	make --directory src/ main
	cp -f src/vpn* src/hamcore.se2 src/ReadMeFirst_License.txt priv/
	true
