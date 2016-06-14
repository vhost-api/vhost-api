require ["fileinto"];
# rule:[arch-dev-public]
if header :contains "list-id" "arch-dev-public.archlinux.org"
{
	fileinto "Lists.arch-dev-public";
	stop;
}
# rule:[arch-announce]
if header :contains "list-id" "arch-announce.archlinux.org"
{
	fileinto "Lists.arch-announce";
	stop;
}
# rule:[filebin-general]
if header :contains "list-id" "filebin-general.lists.server-speed.net"
{
	fileinto "Lists.filebin-general";
	stop;
}
# rule:[oss-sec]
if header :contains "list-id" "oss-security.lists.openwall.com"
{
	fileinto "Lists.oss-security";
	stop;
}
# rule:[GitHub]
if allof (header :is "from" "notifications@github.com")
{
	fileinto "GitHub";
}
# rule:[Steam]
if header :matches "from" "@steampowered.com"
{
	fileinto "Steam";
}
