--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import qualified GHC.IO.Encoding as E


--------------------------------------------------------------------------------
main :: IO ()
main = do
    E.setLocaleEncoding E.utf8
    hakyll $ do
        match "images/*" $ do
            route   idRoute
            compile copyFileCompiler

        match "images/**/*" $ do
                    route   idRoute
                    compile copyFileCompiler

        match "font/*" $ do
                route   idRoute
                compile copyFileCompiler

        match "js/*" $ do
                route   idRoute
                compile copyFileCompiler

        match "css/*" $ do
            route   idRoute
            compile compressCssCompiler

--        match (fromList ["about.rst"]) $ do
--            route   $ setExtension "html"
--            compile $ pandocCompiler
--                >>= loadAndApplyTemplate "templates/default.html" defaultContext
--                >>= relativizeUrls

        match "posts/*" $ do
            route $ setExtension "html"
            compile $ pandocCompiler
                >>= loadAndApplyTemplate "templates/post.html"    postCtx
                >>= loadAndApplyTemplate "templates/default.html" postCtx
                >>= relativizeUrls

        create ["archive.html"] $ do
            route idRoute
            compile $ do
                posts <- recentFirst =<< loadAll "posts/*"
                let archiveCtx =
                      listField "posts" postCtx (return posts) `mappend`
                      constField "title" "Archives"            `mappend`
                      defaultContext

                makeItem ""
                    >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                    >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                    >>= relativizeUrls

        create ["about.html"] $ do
            route idRoute
            compile $ do
              let aboutCtx =
                    constField "title" "About me"            `mappend`
                    defaultContext
              makeItem "" >>=
                  loadAndApplyTemplate "templates/about.html" aboutCtx
                  >>= loadAndApplyTemplate "templates/default.html" aboutCtx
                  >>= relativizeUrls

        match "index.html" $ do
            route idRoute
            compile $ do
                posts <- recentFirst =<< loadAll "posts/*"
                let indexCtx =
                        listField "posts" postCtx (return posts) `mappend`
                        constField "title" "Home"                `mappend`
                        defaultContext

                getResourceBody
                    >>= applyAsTemplate indexCtx
                    >>= loadAndApplyTemplate "templates/default.html" indexCtx
                    >>= relativizeUrls

        match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext
