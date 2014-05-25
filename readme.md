[The setup docs](http://graphite.readthedocs.org/en/latest/install.html) for graphite-webapp are terrible.

```bash
vagrant up
vagrant ssh
# start the graphite carbon daemons
# todo: daemonize
sudo /opt/graphite/bin/carbon-cache.py start
sudo /opt/graphite/bin/carbon-aggregator.py start
logout
```

The virtual machine forwards ports to that you can:

* Talk to the webapp (:8081)
* Send data to the carbon-cache daemon (:22003)
* Send data to the carbon-aggregator daemon (:22023)

## To send counter data directly to the `carbon-cache` daemon:

```bash
# From the host machine
echo "test.mycounter 100 `date +%s`" | nc localhost 22003"
```

The counter data should show up in the webapp : http://localhost:8081

When you send counter data directly to `carbon-cache`, the value recorded for the
time interval is the *last* value `carbon-cache` receives during that interval.

If the recording interval is 60 seconds, and you send the following data during that time:

100
101
99
102
100
52287

...`carbon-cache` will record a value of 52287 for that interval.

## To send counter data to the `carbon-aggregator` daemon:

```
# From the host machine
$ echo "test.mycounter 100 `date +%s`" | nc localhost 22023"
```

`carbon-aggregator` buffers incoming counter data, and runs aggregate operations
before flushing a single aggregate value to the `carbon-cache` daemon. The aggregating
behaviour is defined in the file `aggregation-rules.conf`.

The aggregating behaviour can be defined on a per-counter basis, or more generically using
patterns. The following config will generate average metrics for any metric passed in to it:

```
averageOf.<metric> (60) = avg <<metric>>
```

If we send the following values for the counter "test.mycounter" to `carbon-aggregator`
in a 60-second recording interval:

100
101
99
102
100
52287

the following metrics will appear in the graphite webapp for that interval:

test.mycounter: 52287
averageOf.test.mycounter: 8798.166666667


## Stupid computers

Each metric you send to carbon creates a .wsp (whisper) file on disk. Periods (.) in
the name of the metric indicate a folder hierarchy.

For example, metrics submitted with the name
`test.mycounter` will end up in `/opt/graphite/storage/whisper/test/mycounter.wsp`

If you generate *sub-metrics*, they will end up in subfolders, e.g. 
`test.mycounter.v1` will end up in `/opt/graphite/storage/whisper/test/mycounter/v1.wsp`

BUT when the webapp searches the directory tree for metrics, it STOPS as soon as it
finds a metric, and DOES NOT show folders for the sub-metrics. In the example above,
the webapp would show `test.mycounter` as a *metric*, but would not also show a
`test.mycounter` *folder* that you can expand to see the `v1` counter inside it.

To show the `v1` counter, you have to first delete the `/test/mycounter.wsp` file.
