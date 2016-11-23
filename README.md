# Next steps

 - [x] import automatici (`@HtmlImport`)
 - [x] ottenere i percorsi direttamente da pub per i moduli importati
 - generare il wrapper degli elementi noti automaticamente usando una rule bazel
   - scarica l'elemento da github
   - la rule hydrolizza l'elemento 
	- RICORDA : anche il tool per hydrolisis dovrebbe essere un target 
   - genera il wrapper dart
   - modifica il codice HTML correggendo gli imports
   - produce il BUILD 

## Note

Con il wrapper la figata è che per usare un elemento JS basta dichiararlo come dipendenza, es.:

    polymer_import_bower(
     name='paper-dialog',
     repository='http://github.com/PolymerElements/paper-dialog')
