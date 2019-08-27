# Top Coders Perú
Based on Github Stats

## ¿Cómo se calcula el Raking?

Para generar el ranking se realiza un calculo del indice rockstar, considerando las siguientes variables:

- Popularidad (_Número de seguidores_) 
- Impacto (_Número de estrellas en repositorios propios_)
- Actividad (_Número de commits en el ultimo año_)
- OpenSource (_Numero de proyectos personales publicos_) 

El indice de cada una de estas variables se divide entre el maximo general encontrado para cada variable, esto permitira obtener un indice relativo al total de la muestra.

![CodeCogsEqn.svg](images/CodeCogsEqn.svg)

Con esto se obtiene un indice que representa que tan lejos estamos de los maximos valores encontrados para cada variable.

## ¿Cómo funciona?

La pagina esta basada en Jekyll para la generacion de contenido estatico y de Travis CI para la generacion automatica de nuevos deploys cada dia, manteniendo actualizada la información del ranking.