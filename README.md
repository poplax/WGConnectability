WGConnectability
================

Simple library for sending http pings in objC


example code to check connectability to Facebook:

static WGConnectability *connectability;
connectability = [WGConnectability new];
[connectability connectToAddressAsync:@"graph.facebook.com" onSuccess:^{
	// able to reach facebook
} onFail:^{
	// network is off or timed out
}];

