# Publication and legal notes

This is a project-risk checklist, not legal advice. Reverse-engineering,
copyright, anti-circumvention and trademark rules vary by country and by the
facts of a particular case. Publishing source code cannot guarantee that no
company will send a complaint or takedown request.

The project is aimed at interoperability with lawfully acquired hardware. In
Chile, Article 71 Ñ of Law 17.336 contains an exception concerning reverse
engineering of a lawfully obtained program copy for compatibility or research
and development, subject to limits. In the United States, 17 U.S.C. §1201(f)
contains an interoperability exception with its own conditions. Those texts
should be read directly, and neither automatically decides every copyright,
contract or jurisdictional question:

- Chile, Ley 17.336, Artículo 71 Ñ:
  <https://www.bcn.cl/leychile/Navegar/imprimir?idNorma=28933&idParte=8917017>
- United States, 17 U.S.C. §1201(f):
  <https://uscode.house.gov/view.xhtml?req=%28title%3A17+section%3A1201+edition%3Aprelim%29>

Before publishing:

1. Publish only the contents of this `publish/` tree in a new Git history.
2. Run `make check` and inspect `git status` plus `git diff --cached`.
3. Confirm that every staged file belongs to the documented public Linux
   implementation.
4. Keep the unofficial/non-affiliation notice prominent and do not use vendor
   logos or branding that implies sponsorship.
5. Keep an accurate record of lawful acquisition, research purpose, human
   testing and authorship; do not call the work clean-room.
6. Consider review by a Chilean intellectual-property lawyer before a public
   launch, especially if a complaint arrives.

GitHub can disable access in response to a facially valid DMCA notice. A
counter-notice is a legal step and can be followed by litigation. Read
GitHub's current policies before responding:

- <https://docs.github.com/en/site-policy/content-removal-policies/dmca-takedown-policy>
- <https://docs.github.com/en/site-policy/content-removal-policies/github-trademark-policy>

If a credible complaint is received, preserve the notice and repository
history, avoid an impulsive admission or counter-notice, and obtain qualified
legal advice. A project's GPL license does not grant permission to redistribute
third-party proprietary software or trademarks.
