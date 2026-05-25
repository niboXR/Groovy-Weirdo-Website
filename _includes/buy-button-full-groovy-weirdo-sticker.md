
<div id='product-component-1779676532977'></div>
<script type="text/javascript">
/*<![CDATA[*/
(function () {
  var scriptURL = 'https://sdks.shopifycdn.com/buy-button/latest/buy-button-storefront.min.js';
  if (window.ShopifyBuy) {
    if (window.ShopifyBuy.UI) {
      ShopifyBuyInit();
    } else {
      loadScript();
    }
  } else {
    loadScript();
  }
  function loadScript() {
    var script = document.createElement('script');
    script.async = true;
    script.src = scriptURL;
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(script);
    script.onload = ShopifyBuyInit;
  }
  function ShopifyBuyInit() {
    var client = ShopifyBuy.buildClient({
      domain: '7xt17a-jm.myshopify.com',
      storefrontAccessToken: '4cf0a7e252fa623b9b248587fa9921e5',
    });
    ShopifyBuy.UI.onReady(client).then(function (ui) {
      ui.createComponent('product', {
        id: '8253393141826',
        node: document.getElementById('product-component-1779676532977'),
        moneyFormat: '%24%7B%7Bamount%7D%7D',
        options: {
  "product": {
    "styles": {
      "product": {
        "@media (min-width: 601px)": {
          "max-width": "100%",
          "margin-left": "0",
          "margin-bottom": "50px"
        },
        "text-align": "left"
      },
      "title": {
        "font-family": "Shrikhand, sans-serif",
        "font-size": "26px",
        "color": "#8a5cf5"
      },
      "button": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "bold",
        "font-size": "16px",
        "padding-top": "16px",
        "padding-bottom": "16px",
        ":hover": {
          "background-color": "#7c53dd"
        },
        "background-color": "#8a5cf5",
        ":focus": {
          "background-color": "#7c53dd"
        },
        "border-radius": "40px"
      },
      "quantityInput": {
        "font-size": "16px",
        "padding-top": "16px",
        "padding-bottom": "16px"
      },
      "price": {
        "font-family": "Shrikhand, sans-serif",
        "font-size": "18px"
      },
      "compareAt": {
        "font-family": "Shrikhand, sans-serif",
        "font-size": "15.299999999999999px"
      },
      "unitPrice": {
        "font-family": "Shrikhand, sans-serif",
        "font-size": "15.299999999999999px"
      },
      "description": {
        "font-family": "Shrikhand, sans-serif"
      }
    },
    "layout": "horizontal",
    "contents": {
      "img": false,
      "imgWithCarousel": true,
      "description": true
    },
    "width": "100%",
    "text": {
      "button": "Add to cart"
    },
    "googleFonts": [
      "Shrikhand"
    ]
  },
  "productSet": {
    "styles": {
      "products": {
        "@media (min-width: 601px)": {
          "margin-left": "-20px"
        }
      }
    }
  },
  "modalProduct": {
    "contents": {
      "img": false,
      "imgWithCarousel": true,
      "button": false,
      "buttonWithQuantity": true
    },
    "styles": {
      "product": {
        "@media (min-width: 601px)": {
          "max-width": "100%",
          "margin-left": "0px",
          "margin-bottom": "0px"
        }
      },
      "button": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "bold",
        "font-size": "16px",
        "padding-top": "16px",
        "padding-bottom": "16px",
        ":hover": {
          "background-color": "#7c53dd"
        },
        "background-color": "#8a5cf5",
        ":focus": {
          "background-color": "#7c53dd"
        },
        "border-radius": "40px"
      },
      "quantityInput": {
        "font-size": "16px",
        "padding-top": "16px",
        "padding-bottom": "16px"
      },
      "title": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "bold",
        "font-size": "26px",
        "color": "#4c4c4c"
      },
      "price": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "normal",
        "font-size": "18px",
        "color": "#4c4c4c"
      },
      "compareAt": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "normal",
        "font-size": "15.299999999999999px",
        "color": "#4c4c4c"
      },
      "unitPrice": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "normal",
        "font-size": "15.299999999999999px",
        "color": "#4c4c4c"
      },
      "description": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "normal",
        "font-size": "14px",
        "color": "#4c4c4c"
      }
    },
    "googleFonts": [
      "Shrikhand"
    ],
    "text": {
      "button": "Add to cart"
    }
  },
  "option": {},
  "cart": {
    "styles": {
      "button": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "bold",
        "font-size": "16px",
        "padding-top": "16px",
        "padding-bottom": "16px",
        ":hover": {
          "background-color": "#7c53dd"
        },
        "background-color": "#8a5cf5",
        ":focus": {
          "background-color": "#7c53dd"
        },
        "border-radius": "40px"
      }
    },
    "text": {
      "total": "Subtotal",
      "button": "Checkout"
    },
    "googleFonts": [
      "Shrikhand"
    ]
  },
  "toggle": {
    "styles": {
      "toggle": {
        "font-family": "Shrikhand, sans-serif",
        "font-weight": "bold",
        "background-color": "#8a5cf5",
        ":hover": {
          "background-color": "#7c53dd"
        },
        ":focus": {
          "background-color": "#7c53dd"
        }
      },
      "count": {
        "font-size": "16px"
      }
    },
    "googleFonts": [
      "Shrikhand"
    ]
  }
},
      });
    });
  }
})();
/*]]>*/
</script>
