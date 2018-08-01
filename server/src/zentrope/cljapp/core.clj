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
   [integrant.core :as ig]
   [nrepl.server :refer [start-server stop-server]]
   [nrepl.core :as repl]
   [org.httpkit.server :as httpd]))

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
  (fn [repl cmd]
    (:op cmd)))

(defmethod repl-op :default [_ cmd]
  (println " - unknown op" (pr-str cmd))
  {:error :unknown-op :command cmd})

(defmethod repl-op "eval" [repl cmd]
  (let [msg {:op :eval :code (:expr cmd) :session (:session repl)}]
    (doall (repl/message (:client repl) msg))))

(defmethod repl-op "ns-all" [repl _]
  (->> (all-ns)
       (mapv (memfn getName))
       sort
       (mapv #(hash-map :name %))
       (mapv #(assoc % :symbols (resolve-symbols (:name %))))))

(defmethod repl-op "ping" [repl _]
  {:op :ping :data :pong})

(defmethod repl-op "source" [repl cmd]
  {:source (or (clojure.repl/source-fn (symbol (:symbol cmd)))
               (format "Source for '%s' not found." (:symbol cmd)))})

;;; Web Handlers

(defn- body-of
  [r]
  (let [b (:body r)]
    (if (string? b) b (slurp b))))

(defn- tresp
  [body]
  {:status 200 :body body :headers {"content-type" "text/plain"}})

(defn- jresp
  [value]
  (let [doc (json/write-str value)]
    {:status 200
     :headers {"content-type" "application/json"}
     :body doc}))

(defn- ping [r]
  (tresp "OK"))

(defn- repl [req repl]
  (let [cmd (json/read-str (body-of req) :key-fn keyword)
        _ (println " -" (pr-str cmd))
        result (repl-op repl cmd)]
    (jresp result)))

(defn- not-found [r]
  (tresp "Not found"))

(defn- route
  [request repl-client]
  (println (format "%s %s" (name (:request-method request)) (:uri request)))
  (try
    (case (:uri request)
      "/ping" (ping request)
      "/repl" (repl request repl-client)
      (not-found request))
    (catch Throwable t
      (println "   !" (.getMessage t))
      {:status 500 :body (.getMessage t) :headers {"content-type" "text/plain"}})))

;;; Configuration

(def ^:private config
  {:nrepl-server {:port 61016}
   :nrepl-client {:port 61016 :server (ig/ref :nrepl-server)}
   :httpd {:port 60006 :repl (ig/ref :nrepl-client)}})

;;; Service management

(defmethod ig/init-key :httpd
  [_ {:keys [repl port]}]
  (println (format "Starting httpd server on %s." port))
  (httpd/run-server #(route % repl) {:port port :worker-name-prefix "http."}))

(defmethod ig/halt-key! :httpd
  [_ server]
  (println "Stopping httpd server.")
  (when server
    (server)))

(defmethod ig/init-key :nrepl-server
  [_ {:keys [port]}]
  (println "Starting nrepl server.")
  (start-server :port port))

(defmethod ig/halt-key! :nrepl-server
  [_ server]
  (println "Stopping nrepl server.")
  (stop-server server))

(defmethod ig/init-key :nrepl-client
  [_ {:keys [port]}]
  (println "Starting nrepl client.")
  (let [conn (repl/connect :port port)
        client (repl/client conn 1000)
        session (repl/new-session client)]
    {:conn conn :client client :session session}))

(defmethod ig/halt-key! :nrepl-client
  [_ client]
  (println "Stopping nrepl client.")
  (when-let [conn (:conn client)]
    (.close conn)))

;;; Bootstrap

(defn- hook-shutdown!
  [f]
  (doto (Runtime/getRuntime)
    (.addShutdownHook (Thread. f))))

(defn -main
  [& args]
  (println "Welcome to WIP")
  (let [lock (promise)
        system (ig/init config)]
    (hook-shutdown! #(do (println "Stopping.")
                         (ig/halt! system)
                         (deliver lock :release)))
    @lock
    (println "Halt!")))
