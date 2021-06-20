
(
cd log && 
for f in *.c.log; do
	grep -H '' "$f" "${f%.c.log}.s.log" | sort -n -k2 -t:
done
)
