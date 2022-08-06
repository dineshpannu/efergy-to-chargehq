# efergy-to-chargehq

A PowerShell script which reads current values from your [Eferfy](https://efergy.com/) energy monitor and passes it to [Charge HQ](https://chargehq.net/). 

Developed against Efergy Engage with 2 CT sensors which track solar production and house usage. Charge HQ uses these values to charge your EV battery maximising solar energy use.

Modify `$EFERGY_TOKEN` and `$CHARGE_HQ_SITEID` at the top of the script and run it as a Windows scheduled task every minute.
