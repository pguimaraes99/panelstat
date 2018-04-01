# PANELSTAT
> Descriptive statistics for panel data sets

`panelstat` is a [Stata](http://www.stata.com/) tool to explore unbalanced panel
data sets. The software was developed to explore in detail a panel data set. The
options that were added reflect particular needs felt by the restricted group of
users at BPlim - the microdata laboratory at the Banco de Portugal - who use it
on a regular basis. No attention has been given to formatting of outputs.

## Installation

`panelstat` is not in SSC. To install, run the following within Stata:

```
cap ado uninstall panelstat
net install panelstat, from("https://github.com/pguimaraes99/panelstat/raw/master/")
```

## Author

Paulo Guimarães <br>
Banco de Portugal <br>
Email: [pguimaraes2001@gmail.com](mailto:pguimaraes2001@gmail.com)

## Acknowledgments

This package benefited from many comments by Marta Silva and Emma Zhao.
