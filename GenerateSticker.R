library(hexSticker)
library(tidyverse)

p <- ggplot(aes(x = mpg, y = -wt), data = mtcars) + geom_point(size = 0.5, color = "#ffffff") +
  geom_smooth(method="lm", size=0.5, color="#a49363", se=FALSE)
p <- p + theme_void() + theme_transparent()
 

sticker(p, package="MATH 2025", p_size=20, s_x=1, s_y=0.90, s_width=1.3, s_height=0.9,
        h_fill="#412d5e", h_color = "#a49363",
        p_color="#bbbbbb",
        filename="images/sticker2025.png")

