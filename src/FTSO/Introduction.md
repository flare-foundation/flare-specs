# Introduction

The FTSO (Flare Time Series Oracle) is an enshrined protocol of the Flare Network that periodically determines time series values for a collection of data feeds, secured by consensus among Flare's data providers. Typically, these data feeds represent prices of various assets, so that the FTSO provides access to decentralized price estimates for various smart contracts operating on the network and beyond. The FTSO supports two types of feeds: _anchor_ feeds updating every $90$ seconds, and _block-latency_ feeds determined by updates in intermediary blocks. The values of the anchor feeds are determined by taking a weighted average of estimates submitted by each provider, whereas the block-latency feeds select random providers to provide a small delta update in each block.

