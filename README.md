# Search Result Page Investigation ([T179528](https://phabricator.wikimedia.org/T179528))

We're [previously identified](https://commons.wikimedia.org/w/index.php?title=File%3AWikimedia_Foundation_Readers_metrics_Q4_2016-17_(Apr-Jun_2017).pdf&page=26) that in the TSS2 schema, 55% of sessions only use autocomplete, 9% only make fulltext search, and 36% of sessions include a mix of both. That's 45% of sessions on desktop (that are in TSS2) that see a SRP, yet we're only seeing a [couple million pageviews](https://commons.wikimedia.org/w/index.php?title=File:Wikimedia_Foundation_Readers_metrics_Q4_2016-17_(Apr-Jun_2017).pdf&page=30) from desktop devices. Additionally and related, since autocomplete is built into our search bar and the click through rate is nearly 100%, then you wouldn't expect to see such a high proportion of sessions also using full text search. 55% of search sessions only auto + 36% both = 91% of sessions use autocomplete, there is a nearly 100% CTR and 40% of those end up also using full-text.

## Findings

Updated numbers from my pull of 2 weeks of data from 11/20-12/04. On a daily basis:

- 92-95% of sessions performed an autocomplete search
    - Of sessions that used autocomplete, 5-10% of them searched using full-text search separate from their autocomplete searching. (e.g. someone doing a full-text search and then later doing an autocomplete one and vice versa).
    - Of sessions that start with autocomplete, 17-22% of them switch to a full-text search. Almost all of these are people who get 0 autocomplete results by the time they're done writing the full search query they intended, so they just automatically go on to full-text SRP.
- 23-28% of sessions performed a full-text search
    - Of sessions that included a full-text search, 70-78% of them started their search session with an autocomplete search.
    - Of sessions that included a full-text search, 22-30% of them started their search session with a full-text search.
- 72-77% sessions used autocomplete only
    - 85-93% clickthrough rate
- 5-8% sessions used full-text only, and
    - 17-47% clickthrough rate
- 17-21% sessions used both autocomplete & full-text search (either separate or switching from autocomplete to full-text)
    - 57-73% overall session clickthrough rate (actual clickthrough rate which excludes clicks that are the user going from autocomplete to perform full-text search)
    - 35-47% clickthrough rate when performing an autocomplete search
    - 41-54% clickthrough rate when performing a full-text search
