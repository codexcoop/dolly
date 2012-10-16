## Dolly

Dolly è unʼapplicazione web per la gestione di una biblioteca di oggetti digitali.
Versione corrente: **0.9.8**

## Requisiti

* Ruby 1.8.7
* Rails 2.3.14
* Gemme Ruby elencate nel file config/environment.rb
* YAZ
* ImageMagick
* Database PostgreSQL 9.1
* Webserver configurato per applicazioni Rails

## Installazione

1. Predisporre il proprio computer con il software indicato nei Requisiti
2. Creare un file di configurazione per il database: config/database.yml. Vedi config/database-example.yml
3. Eseguire il task RAILS_ENV=production rake gems:install
4. Eseguire il task RAILS_ENV=production rake db:setup
5. Avviare il webserver

L'utente per il primo login è:

* user: admin_dolly
* pass: admin_dolly

## Crediti

Dolly è un progetto promosso da:

* Regione Lombardia, Direzione Generale Istruzione, Formazione e Cultura
* Università degli Studi di Pavia

## Autori

Codex Società Cooperativa, Pavia

* [http://www.codexcoop.it](http://www.codexcoop.it)

## Licenza

Dolly è rilasciato sotto licenza GNU General Public License v2.0 o successive.
