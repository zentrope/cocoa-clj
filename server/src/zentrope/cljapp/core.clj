;;;
;;; Copyright (c) 2018-present Keith Irwin
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published
;;; by the Free Software Foundation, either version 3 of the License,
;;; or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see
;;; <http://www.gnu.org/licenses/>.
;;;

(ns zentrope.cljapp.core
  (:require
   [clojure.data.json :as json]
   [clojure.repl :refer [source-fn]]
   [nrepl.server :refer [start-server stop-server]]
   [nrepl.core :as repl])
  (:import
   (java.net InetSocketAddress)
   (com.sun.net.httpserver HttpServer HttpHandler)))

;;; Repl Client Handlers

(def ^:private reasonable
  [:ns :name :dynamic :private :macro :deprecated])

(def ^:private defaults
  {:private false :macro false :dynamic false :deprecated false})

(defn- munge-symbols
  [symbol-map]
  (let [m (merge defaults (select-keys symbol-map reasonable))]
    (if (string? (:deprecated m))
      (assoc m :deprecated true)
      m)))

(defn- resolve-symbols
  [namespace]
  (->> (symbol namespace)
       ns-interns
       vals
       (mapv meta)
       (mapv #(assoc % :ns (.getName (:ns %))))
       (mapv #(munge-symbols %))
       (sort-by :name)))

(defmulti ^:private repl-op
  (fn [cmd repl]
    (:op cmd)))

(defmethod repl-op :default [cmd _]
  {:error :unknown-op :command cmd})

(defmethod repl-op "eval" [cmd repl]
  (let [msg {:op :eval :code (:expr cmd) :session (:session repl)}]
    (doall (repl/message (:client repl) msg))))

(defmethod repl-op "ns-all" [cmd repl]
  (->> (all-ns)
       (mapv (memfn getName))
       sort
       (mapv #(hash-map :name %))
       (mapv #(assoc % :symbols (resolve-symbols (:name %))))))

(defmethod repl-op "ping" [_ repl]
  {:op :ping :data :pong})

(defmethod repl-op "source" [cmd repl]
  {:source (or (clojure.repl/source-fn (symbol (:symbol cmd)))
               (format "Source for '%s' not found." (:symbol cmd)))})

;;; Configuration

(def ^:private http-port 60006)
(def ^:private nrepl-port 61016)

;;; Web server

(defn- handle-repl
  [repl]
  (reify HttpHandler
    (handle [_ exchange]
      (let [response (-> (.getRequestBody exchange)
                         (slurp)
                         (json/read-str :key-fn keyword)
                         (repl-op repl)
                         (json/write-str))]
        (doto exchange
          (.setAttribute "content-type" "application/json")
          (.sendResponseHeaders 200 (count response)))
        (with-open [out (.getResponseBody exchange)]
          (.write out (.getBytes response)))))))

(defn- httpd-server ^HttpServer
  [repl]
  (doto (HttpServer/create (InetSocketAddress. http-port) 0)
    (.createContext "/repl" (handle-repl repl))
    (.setExecutor nil)
    (.start)))

;;; Services

(defn- start-app
  []
  (let [server  (start-server :port nrepl-port)
        conn    (repl/connect :port nrepl-port)
        client  (repl/client conn 1000)
        session (repl/new-session client)
        repl    {:conn conn :client client :session session}
        httpd   (httpd-server repl)]
    {:server #(stop-server server)
     :httpd  #(.stop httpd 0)
     :client #(.close conn)}))

(defn- stop-app
  [{:keys [httpd server client httpd]}]
  (client)
  (server)
  (httpd))

;;; Bootstrap

(defn- hook-shutdown!
  [f]
  (doto (Runtime/getRuntime)
    (.addShutdownHook (Thread. f))))

(defn -main
  [& args]
  (println (format "Cocoa CLJ Server, port %s." http-port))
  (let [lock (promise)
        app (start-app)]
    (hook-shutdown! #(deliver lock :release))
    @lock
    (stop-app app)))
