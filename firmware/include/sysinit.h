// Source: http://www.seanet.com/~karllunt/bareteensy31.html

void sysinit(void);
void trace_clk_init(void);
void fb_clk_init(void);
int32_t pll_init(int8_t  prdiv_val, int8_t vdiv_val);
void wdog_disable(void);
