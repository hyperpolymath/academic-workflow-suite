const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, argv) => {
  const isProduction = argv.mode === 'production';

  return {
    entry: {
      // Main add-in entry point
      addin: './src/AWAPAddin.bs.js',
      // Commands page for ribbon buttons
      commands: './src/RibbonCommands.bs.js',
      // Task pane
      taskpane: './src/TaskPane.bs.js',
    },

    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: '[name].js',
      clean: true,
    },

    resolve: {
      extensions: ['.js', '.bs.js', '.json'],
      alias: {
        '@': path.resolve(__dirname, 'src'),
      },
    },

    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
            options: {
              presets: ['@babel/preset-env'],
            },
          },
        },
        {
          test: /\.css$/,
          use: ['style-loader', 'css-loader'],
        },
        {
          test: /\.(png|jpg|jpeg|gif|svg)$/,
          type: 'asset/resource',
          generator: {
            filename: 'assets/[name][ext]',
          },
        },
      ],
    },

    plugins: [
      // Generate commands.html
      new HtmlWebpackPlugin({
        template: './public/commands.html',
        filename: 'commands.html',
        chunks: ['commands'],
        inject: 'body',
      }),

      // Generate taskpane.html
      new HtmlWebpackPlugin({
        template: './public/taskpane.html',
        filename: 'taskpane.html',
        chunks: ['taskpane'],
        inject: 'body',
      }),

      // Copy static assets
      new CopyWebpackPlugin({
        patterns: [
          {
            from: 'public/assets',
            to: 'assets',
            noErrorOnMissing: true,
          },
          {
            from: 'manifest.xml',
            to: 'manifest.xml',
          },
        ],
      }),
    ],

    devServer: {
      static: {
        directory: path.join(__dirname, 'dist'),
      },
      port: 3000,
      hot: true,
      https: true,
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
      client: {
        overlay: {
          errors: true,
          warnings: false,
        },
      },
    },

    devtool: isProduction ? 'source-map' : 'eval-source-map',

    optimization: {
      minimize: isProduction,
      splitChunks: {
        chunks: 'all',
        cacheGroups: {
          vendor: {
            test: /[\\/]node_modules[\\/]/,
            name: 'vendor',
            priority: 10,
          },
        },
      },
    },

    performance: {
      hints: isProduction ? 'warning' : false,
      maxEntrypointSize: 512000,
      maxAssetSize: 512000,
    },

    stats: {
      colors: true,
      modules: false,
      children: false,
      chunks: false,
      chunkModules: false,
    },
  };
};
