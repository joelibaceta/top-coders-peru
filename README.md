# Top Coders Perú
Based on Github Stats

[![CodeCogsEqn.svg](images/demo.png)](http://joelibaceta.github.io/top-coders-peru/)

<br/>

## ¿Cómo se calcula el Raking?

Para generar el ranking se realiza un calculo del indice rockstar, considerando las siguientes variables:

- Popularidad (_Número de seguidores_) 
- Impacto (_Número de estrellas en repositorios propios_)
- Actividad (_Número de commits en el ultimo año_)
- OpenSource (_Numero de proyectos personales publicos_) 

El indice de cada una de estas variables se divide entre el maximo general encontrado para cada variable, esto permitira obtener un indice relativo al total de la muestra.

<br/>

![CodeCogsEqn.svg](images/CodeCogsEqn.svg)

<br/>

## ¿Cómo funciona?

La pagina esta basada en Jekyll para la generacion de contenido estatico y de Travis CI para la generacion automatica de nuevos deploys cada dia, manteniendo actualizada la información del ranking.

## ¿Como Contribuir?

1. Crear un issue con la descripcion de la contribucion 
2. Hacer un fork del proyecto
3. Hacer los cambios y enviar un Pull Request

### Para iniciar el proyecto localmente necesitas 

- Ejecutar `bundle install`
- Ejecutar `jekyll build`
- Podras ver el sitio web generado en la carpeta `_site`