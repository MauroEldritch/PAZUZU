# PAZUZU: Portainer Authentication Zap Using Zero Utilities

Pazuzu is a ruby exploit for vulnerable Portainer instances (those running with the --no-auth switch by default.
When tested, Pazuzu found 300+ vulnerable containers among many instances. All of them hosted government related information, and are already patched.

PAZUZU was featured @ DevFest Siberia 2018 by its original author (Mauro Cáseres / Mauro Eldritch).
```
#Run with STARTING_IP and ENDING_IP as arguments:

./pazuzu.rb 192.168.0.1 192.168.0.10
```

Pazuzu comes bundled with Karras, a special tool meant to destroy Pazuzu's devilish containers. Invoke it to safely get rid of them and clean your system. It is the only recommended way, as it cleans the messy volumes used by Portainer.

```
#Back to hell!

./karras.rb
```
